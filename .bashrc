#!/bin/bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=ignorespace:ignoredups:erasedups

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTFILESIZE=999999
export HISTSIZE=999999
export HISTTIMEFORMAT='%F:%T '

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# enables MAIL && MAILCHECK
shopt -s mailwarn
MAIL=/var/mail/"$USER"
MAILCHECK=30

# bindings
bind -m vi-insert "\C-p":dynamic-complete-history
bind -m vi-insert "\C-n":menu-complete

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  . /etc/bash_completion
fi

# prompt
_prompt_color_enabled() {
  git config --get-colorbool color.prompt true >/dev/null
}
_prompt_color() {
  git config --get-color "color.prompt.$1" "$2" 2>/dev/null
}
_prompt_apply_color() {
  local output="$1" color="$2" default="$3"
  if _prompt_color_enabled; then
    _prompt_color "$color" "$default"
    echo -ne "${output}"
    _prompt_color "reset" ""
  else
    echo -ne "$output"
  fi
}
_prompt_status()
{
  local status=$?
  if [ "$status" != 0 ]; then
    _prompt_apply_color "[$status] " "exitstatus" "bold red"
  fi
}
_prompt_date() {
  _prompt_apply_color "$(date +%T)" "date" "white"
}
_prompt__hostname() {
  _prompt_apply_color " $(hostname)" "hostname" "blue"
}
_prompt_git() {
  local subdir
  if ! subdir=`git rev-parse --show-prefix 2>/dev/null`; then
    _prompt_apply_color " ${PWD}" "prefix" "gray"
    return
  fi
  subdir="${subdir%/}"
  local prefix="${PWD%/$subdir}"
  _prompt_apply_color " ${prefix/*\/}${subdir:+/$subdir}" "prefix" "gray"
  local branch=`git symbolic-ref -q HEAD 2>/dev/null`
  [ -n "$branch" ] && branch=${branch#refs/heads/} || branch=`git rev-parse --short HEAD 2>/dev/null`
  _prompt_apply_color " $branch" "branch" "cyan"
  local git_dir="$(git rev-parse --git-dir 2>/dev/null)"
  if test -d "$git_dir/rebase-merge"; then
    local marker="(rebase)"
  else
    if test -f "$git_dir/MERGE_HEAD"; then
      local marker="(merge)"
    fi
  fi
  _prompt_apply_color "$marker" "marker" "red"
  local output
  IFS='' output=$(git status --porcelain 2>/dev/null | cut -c-2 | sort -u)
  local staged=$(cut -c1 <<< "$output" | sort -u | grep -v -e ' ' -e '?' -e '!' | tr -d \\n)
  if [ "$staged" ]; then
    _prompt_apply_color " $staged" "clean" "green"
  fi
  local unstaged=$(cut -c2 <<< "$output" | sort -u | grep -v ' ' | tr -d \\n)
  if [ "$unstaged" ]; then
    _prompt_apply_color " $unstaged" "dirty" "red"
  fi
}
_prompt_jobscount()
{
  local count=$(jobs -p | wc -l | tr -d ' ')
  if [ $count -gt 0 ]; then
    _prompt_apply_color " [$count]" "jobscount" "yellow"
  fi
}
PS1='`_prompt_status``_prompt_date``_prompt__hostname``_prompt_git``_prompt_jobscount`\$ '

# aliases
alias ls='ls -F'
alias ll='ls -l'
complete -o default -F _longopt ll
alias la='ls -a'
complete -o default -F _longopt la
alias i='pushd'
complete -d i
alias o='popd'
alias u='dirs -v'
alias pipe='$(history -p \!\!) |&'
alias reless='pipe less'
complete -o default -F _longopt reless
alias regrep='pipe grep'
complete -o default -F _longopt regrep
alias cmatrix='cmatrix -lb'
alias mu='mutt -f ~/var/mail/dfanjul'
complete -o default -F _mutt mu
alias emu='exec mutt -f ~/var/mail/dfanjul'
complete -o default -F _mutt emu
alias iocp='ionice -n 7 cp'
complete -o default -F _longopt iocp
alias iomv='ionice -n 7 mv'
complete -o default -F _longopt iomv
alias m='moosic'
complete -o filenames -F _moosic m
alias hgrep='history | grep'
complete -o default -F _longopt hgrep
alias psuxgrep='command ps ux | grep'
complete -o default -F _longopt psuxgrep
alias psaxgrep='command ps ax | grep'
complete -o default -F _longopt psaxgrep
alias less='less -R'
alias co='command'
complete -F _command co
alias puppet-apply-home='sudo puppet apply ~/etc/puppet/main.pp'
complete -o default -F _service puppet-apply-home

# colored aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls -F --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i ~/usr/share/images/$([ $? = 0 ] && echo blue || echo red).gif "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh /usr/bin/lesspipe)"

# functions
halt() {
  sudo -v && \
    run-parts-cron halt -v && \
    tsp -m sudo shutdown -h +1 >/dev/null
}
reboot() {
  sudo -v && \
    run-parts-cron halt -v && \
    tsp -m sudo shutdown -r +1 >/dev/null
}
xlogout() {
  sudo -v && \
    run-parts-cron halt -v && \
    tsp -m gnome-session-quit --logout >/dev/null
}
xhalt() {
  sudo -v && \
    run-parts-cron halt -v && \
    tsp -m gnome-session-quit --power-off >/dev/null
}
down() {
  yes "|" | head -$(($LINES - 3)) && echo v
}
down() {
  echo -e "\\033[6n"
  read -s -d R foo
  lines=$((LINES - $(echo $foo | cut -d \[ -f 2 | cut -d \; -f 1) - 2))
  while [ $lines -gt 0 ]; do
    echo \|
    lines=$((lines - 1))
  done
  echo v
}
reuntil() {
  seconds="$1" && shift || seconds=5
  until $(history -p !!); do
    sleep "$seconds"
  done
}
rewhile() {
  seconds="$1" && shift || seconds=5
  while $(history -p !!); do
    sleep "$seconds"
  done
}
iwhile() {
  while echo && inotifywait -q -e create -e modify -e move -e delete -r . --exclude ".*\\.sw.$"; do
    eval "$*"
    sleep 1
  done
}
function mailtodo {
  echo "$*" | mail -s "$*" dfanjul
}
function mutt {
  command mutt "$@"
  local s=$?
  (cd ~ && {
    for dir in var/mail var/spool; do
      git commit -m $dir $dir &>/dev/null
    done
  })
  return $s
}

# set PATH for private bin folders
if [ -d ~/usr/local/bin ]; then
  PATH=~/usr/local/bin:"$PATH"
fi
if [ -d ~/bin ] ; then
  PATH=~/bin:"$PATH"
fi

# set CDPATH
export CDPATH=.:~:~/src:~/lib/go/src:~/lib/go/src/github.com/daniel-fanjul-alcuten

# sudo configuration
for command in \
    apt-get \
    aptitude \
    debfoster \
    fdisk \
    hibernate \
    iftop \
    iotop \
    shutdown \
    ; do
  alias $command="sudo $command"
done

# git configuration
if type git >/dev/null 2>&1; then
  _complete_git_aliases() {
    COMP_CWORD=$((COMP_CWORD+1))
    COMP_LINE="git $COMP_LINE"
    COMP_POINT=$((COMP_POINT+4))
    COMP_WORDS=(git "${COMP_WORDS[@]}")
    __git_wrap__git_main
  }
  for command in $(git config -l --global | grep ^alias\\. | cut -d= -f1 | cut -c7-)\
      add \
      archive \
      bisect \
      blame \
      branch \
      bundle \
      cherry \
      cherry-pick \
      clean \
      clone \
      commit-tree \
      config \
      describe \
      diff \
      difftool \
      fetch \
      fsck \
      gc \
      help \
      init \
      log \
      ls-files \
      ls-remote \
      ls-tree \
      merge \
      merge-base \
      mergetool \
      mv \
      prune \
      pull \
      push \
      rebase \
      reflog \
      remote \
      repack \
      request-pull \
      reset \
      rev-list \
      rev-parse \
      revert \
      rm \
      shortlog \
      show \
      show-branch \
      stash \
      status \
      submodule \
      tag \
      whatchanged \
      ; do
    alias $command="git $command"
    complete -o bashdefault -o default -o nospace -F _complete_git_aliases $command
  done
fi

# vim configuration
if type vim >/dev/null; then
  export EDITOR=$(which vim)
fi
set -o vi

# ruby configuration
if [ -d ~/lib/ruby ]; then
  export RUBYLIB=~/lib/ruby
fi

# go configuration
# bash < <(curl -s https://raw.github.com/moovweb/gvm/master/binscripts/gvm-installer)
[ -s ~/.gvm/scripts/gvm ] && source ~/.gvm/scripts/gvm
if [ "$(uname)" = Darwin ]; then
  GOMAXPROCS=$(sysctl -n hw.ncpu)
else
  GOMAXPROCS=$(grep ^processor /proc/cpuinfo | wc -l)
fi
alias gf='go fmt ./...'
alias gt='go test ./...'
alias gtc='go test -coverprofile=/tmp/coverage.data && go tool cover -html=/tmp/coverage.data'
alias gb='go build ./...'
alias gm='go build -gcflags -m ./...'
alias gi='go install ./...'
alias gti='gi && gt'

# wcd configuration
if type wcd.exec >/dev/null; then
  wcd() {
    mkdir -p ~/var
    wcd.exec -z 40 -G ~/var "$@"
    . ~/var/wcd.go
    if [ "$STY" ]; then
      screen -X title "$(basename "$PWD")"
    fi
  }
  alias j='wcd -j'
  alias g='wcd -g'
  function _wcd_complete() {
    local list=$(xargs -a ~/.treedata.wcd -r -n 1 -d '\n' basename | sed 's/ .*//' | sort -u)
    COMPREPLY=( $(compgen -W "$list" "$2") )
  }
  for command in wcd j g; do
    complete -F _wcd_complete $command
  done
else
  wcd() {
    for dir in ~/src/* ~/lib/go/src/github.com/daniel-fanjul-alcuten/*; do
      if local dirname=$(basename "$dir") && grep "^$1" &>/dev/null <<<$dirname; then
        cd "$dir" && {
          if [ "$STY" ]; then
            screen -X title "$dirname"
          fi
          echo "$PWD"
          return 0
        }
      fi
    done
    return 1
  }
  alias j=wcd
  alias g=wcd
  for command in wcd j g; do
    complete -o nospace -W "$(ls -1d ~/src/* ~/lib/go/src/github.com/daniel-fanjul-alcuten/* 2>/dev/null | grep -v \* | xargs -n 1 basename | tr "\\n" "\ ")" $command
  done
fi

# ssh configuration
ssh() {
  if [ "$STY" ]; then
    for arg in "$@"; do
      case "$arg" in
        -*) :;;
        *)
          screen -X title "$arg"
          break
          ;;
      esac
    done
  fi
  command ssh "$@"
}

# maven configuration
export BOLD=`tput bold`
export UNDERLINE_ON=`tput smul`
export UNDERLINE_OFF=`tput rmul`
export TEXT_BLACK=`tput setaf 0`
export TEXT_RED=`tput setaf 1`
export TEXT_GREEN=`tput setaf 2`
export TEXT_YELLOW=`tput setaf 3`
export TEXT_BLUE=`tput setaf 4`
export TEXT_MAGENTA=`tput setaf 5`
export TEXT_CYAN=`tput setaf 6`
export TEXT_WHITE=`tput setaf 7`
export BACKGROUND_BLACK=`tput setab 0`
export BACKGROUND_RED=`tput setab 1`
export BACKGROUND_GREEN=`tput setab 2`
export BACKGROUND_YELLOW=`tput setab 3`
export BACKGROUND_BLUE=`tput setab 4`
export BACKGROUND_MAGENTA=`tput setab 5`
export BACKGROUND_CYAN=`tput setab 6`
export BACKGROUND_WHITE=`tput setab 7`
export RESET_FORMATTING=`tput sgr0`
mvn-color()
{
  # filter mvn output using sed
  mvn $@ | sed -e "s/\(\[INFO\]\ \-.*\)/${TEXT_BLUE}${BOLD}\1/g" \
               -e "s/\(\[INFO\]\ \[.*\)/${RESET_FORMATTING}${BOLD}\1${RESET_FORMATTING}/g" \
               -e "s/\(\[INFO\]\ BUILD SUCCESSFUL\)/${BOLD}${TEXT_GREEN}\1${RESET_FORMATTING}/g" \
               -e "s/\(\[WARNING\].*\)/${BOLD}${TEXT_YELLOW}\1${RESET_FORMATTING}/g" \
               -e "s/\(\[ERROR\].*\)/${BOLD}${TEXT_RED}\1${RESET_FORMATTING}/g" \
               -e "s/Tests run: \([^,]*\), Failures: \([^,]*\), Errors: \([^,]*\), Skipped: \([^,]*\)/${BOLD}${TEXT_GREEN}Tests run: \1${RESET_FORMATTING}, Failures: ${BOLD}${TEXT_RED}\2${RESET_FORMATTING}, Errors: ${BOLD}${TEXT_RED}\3${RESET_FORMATTING}, Skipped: ${BOLD}${TEXT_YELLOW}\4${RESET_FORMATTING}/g"
  local m=$?
  # make sure formatting is reset
  echo -ne ${RESET_FORMATTING}
  return $m
}
# override the mvn command with the colorized one.
alias mvn="mvn-color"
# memory
export MAVEN_OPTS='-XX:MaxPermSize=256m -Xmx2048m'
# shortcuts
mi() {
  mvn install -DskipTests=true
}
mci() {
  mvn clean install -DskipTests=true
}
mt() {
  mvn test -DskipTests=false
}
mct() {
  mvn clean test -DskipTests=false
}
mit() {
  mvn install -DskipTests=false
}
mcit() {
  mvn clean install -DskipTests=false
}
mj() {
  mvn jetty:run -DskipTests=true
}
mcj() {
  mvn clean jetty:run -DskipTests=true
}
mij() {
  mvn install jetty:run -DskipTests=true
}
mcij() {
  mvn clean install jetty:run -DskipTests=true
}

# crawl
export CRAWL_DIR=~/.crawl

# down
down

# pal
if type pal >/dev/null; then
  pal -r 7 -c 1
fi

# gvm
if type gvm >/dev/null; then
  gvm use 1.2.1
  GOPATH=~/lib/go:"$GOPATH"
fi

# from
if type from >/dev/null; then
  from -c
fi
