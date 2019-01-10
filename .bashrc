#!/bin/bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=ignorespace:ignoredups:erasedups

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTFILESIZE=999999
export HISTSIZE=999999
# export HISTTIMEFORMAT='%F:%T '

function vi-bash-history() {
  history -a &&
    tac "$HISTFILE" |
    awk '!x[$0]++' |
    tac |
    sponge "$HISTFILE" &&
    exec vi +$ ~/.bash_history
}

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
MAILPATH="$MAIL"

# bindings
bind -m vi-insert "\C-p":dynamic-complete-history
bind -m vi-insert "\C-n":menu-complete

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
  if [ -f /usr/share/bash-completion/completions/git ]; then
    . /usr/share/bash-completion/completions/git
  fi
fi

# prompt
function _prompt_color_enabled() {
  git config --get-colorbool color.prompt true >/dev/null
}
function _prompt_color() {
  git config --get-color "color.prompt.$1" "$2" 2>/dev/null
}
function _prompt_apply_color() {
  local output="$1" color="$2" default="$3"
  if _prompt_color_enabled; then
    _prompt_color "$color" "$default"
    echo -ne "${output}"
    _prompt_color "reset" "reset"
  else
    echo -ne "$output"
  fi
}
function _prompt_status() {
  local status=$?
  if [ "$status" != 0 ]; then
    _prompt_apply_color "[$status] " "status" "bold red"
  fi
}
function _prompt_date() {
  _prompt_apply_color "$(date +%T)" "date" "white"
}
function _prompt__hostname() {
  _prompt_apply_color " $(whoami)@$(hostname)" "hostname" "magenta"
}
function _prompt_systemd() {
  local target=$({ sudo systemctl --type target; systemctl --user --type target;} | grep dfanjul | sed 's/^  *//' | cut -d ' ' -f 1 | sed 's/\.target//' | sort -u | tr '\n' ' ' | sed 's/ $//')
  if [ "$target" ]; then
    _prompt_apply_color " {$target}" "systemd" "cyan"
  fi
}
function _prompt_nmcli() {
  local nmcli=$(nmcli connection show --active 2>/dev/null | tail -n +2 | grep -v 'docker0 *$' | grep -v 'tun0 *$' | cut -f 1 -d ' ' | sort | tr \\n ' ' | sed 's/ $//')
  if [ "$nmcli" ]; then
    _prompt_apply_color " <$nmcli>" "nmcli" "blue"
  fi
}
function _prompt_battery() {
  local state=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep state | cut -f 2 -d : | sed 's/ //g')
  if [ "${state}" = "fully-charged" ]; then
    return
  fi
  local battery=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep percentage | cut -f 2 -d : | sed -e 's/ //g' -e 's/%//g')
  if [ "${battery}" -lt "20" ]; then
    _prompt_apply_color " ${battery}%" "battery" "red"
  elif [ "${battery}" -lt "40" ]; then
    _prompt_apply_color " ${battery}%" "battery" "yellow"
  elif [ "${battery}" -lt "60" ]; then
    _prompt_apply_color " ${battery}%" "battery" "green"
  else
    _prompt_apply_color " ${battery}%" "battery" "cyan"
  fi
  if [ "${state}" = "discharging" ]; then
    _prompt_apply_color "!" "discharging" "red"
  fi
}
function _prompt_dirtyvm() {
  local m1=$(grep ^Dirty /proc/meminfo|cut -c 7-|sed 's/ //g')
  local m2=$(sysctl -n vm.dirty_expire_centisecs)
  local m3=$(sysctl -n vm.dirty_writeback_centisecs)
  _prompt_apply_color " $m1/$m2/$m3" "dirtyvm" "grey"
}
function _prompt_git() {
  local subdir
  if ! subdir=$(git rev-parse --show-prefix 2>/dev/null); then
    _prompt_apply_color " ${PWD}" "git.prefix" "gray"
    return
  fi
  subdir="${subdir%/}"
  local prefix="${PWD%/$subdir}"
  _prompt_apply_color " ${prefix/*\/}${subdir:+/$subdir}" "git.prefix" "gray"
  local branch=$(git symbolic-ref -q HEAD 2>/dev/null)
  [ -n "$branch" ] && branch=${branch#refs/heads/} || branch=$(git rev-parse --short HEAD 2>/dev/null)
  _prompt_apply_color " $branch" "git.branch" "cyan"
  local git_dir="$(git rev-parse --git-dir 2>/dev/null)"
  if test -d "$git_dir/rebase-merge"; then
    local marker="(rebase)"
  else
    if test -f "$git_dir/MERGE_HEAD"; then
      local marker="(merge)"
    fi
  fi
  _prompt_apply_color "$marker" "git.marker" "red"
  local output
  IFS='' output=$(git status --porcelain 2>/dev/null | cut -c-2 | sort -u)
  local staged=$(cut -c1 <<< "$output" | sort -u | grep -v -e ' ' -e '?' -e '!' | tr -d \\n)
  if [ "$staged" ]; then
    _prompt_apply_color " $staged" "git.clean" "green"
  fi
  local unstaged=$(cut -c2 <<< "$output" | sort -u | grep -v ' ' | tr -d \\n)
  if [ "$unstaged" ]; then
    _prompt_apply_color " $unstaged" "git.dirty" "red"
  fi
}
function _prompt_jobscount() {
  local count=$(jobs -p | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    _prompt_apply_color " [$count]" "jobscount" "yellow"
  fi
}
function _prompt_mail() {
  local count=$(from -c | cut -f 3 -d ' ')
  if [ "$count" -gt 0 ]; then
    _prompt_apply_color " ${count}✉" "jobscount" "yellow"
  fi
}
PS1='`_prompt_status``_prompt_date``_prompt__hostname``_prompt_nmcli``_prompt_battery``_prompt_git``_prompt_jobscount``_prompt_mail`\n\$ '

# aliases
alias ls='ls -F'
alias ll='ls -l'
complete -o default -F _longopt ll
alias la='ls -a'
alias less='less -R'
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh /usr/bin/lesspipe)"
complete -o default -F _longopt la
alias pipe='$(history -p \!\!) |&'
alias reless='pipe less'
complete -o default -F _longopt reless
alias regrep='pipe grep'
complete -o default -F _longopt regrep
alias cmatrix='cmatrix -lb'
alias m='moosic'
complete -o filenames -F _moosic m
alias hgrep='history | grep'
complete -o default -F _longopt hgrep
alias psuxgrep='command ps ux | grep'
complete -o default -F _longopt psuxgrep
alias psaxgrep='command ps ax | grep'
complete -o default -F _longopt psaxgrep
alias co='command'
function _complete_command() {
  COMP_LINE="command ${COMP_LINE#co }"
  COMP_POINT=$((COMP_POINT+5))
  COMP_WORDS[0]=command
  _command
}
complete -F _complete_command co
alias alert='notify-send --urgency=low -i ~/usr/share/images/$([ $? = 0 ] && echo blue || echo red).gif -- "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# colored aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls -F --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# sudo aliases
for command in \
  apt \
  apt-get \
  aptitude \
  iftop \
  iotop \
  service \
  ; \
do
  alias $command="sudo $command"
done

# git hooks
mkdir -p ~/.git/hooks
cat > ~/.git/hooks/post-checkout <<EOF
#!/bin/bash
chmod -f -R go-rwx ~/.{ssh,gnupg}
true
EOF
cat > ~/.git/hooks/post-rewrite <<EOF
#!/bin/bash
cat >/dev/null
chmod -f -R go-rwx ~/.{ssh,gnupg}
true
EOF
chmod u+x ~/.git/hooks/post-{checkout,rewrite}
if [ -f ~/usr/share/hub/etc/hub.bash_completion.sh ]; then
  source ~/usr/share/hub/etc/hub.bash_completion.sh
fi

# cd
function postcd() {
  # screen title
  local dir="$(basename "$PWD")"
  if [ "$STY" ]; then
    screen -X title "$dir"
    screen -X chdir "$PWD"
  fi
  # git aliases
  if type git &>/dev/null; then
    function _complete_git_aliases() {
      COMP_CWORD=$((COMP_CWORD+1))
      COMP_LINE="git $COMP_LINE"
      COMP_POINT=$((COMP_POINT+4))
      COMP_WORDS=(git "${COMP_WORDS[@]}")
      __git_wrap__git_main
    }
    for command in \
      $(git config -l | grep ^alias\\. | cut -d= -f1 | cut -c7-) \
      add \
      am \
      apply \
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
      mktree \
      mv \
      patch-id \
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
      worktree \
      ; \
    do
      alias $command="git $command"
      complete -o bashdefault -o default -o nospace -F _complete_git_aliases $command
    done
    if type git-greb &>/dev/null; then
      source <(git-greb --bash _greb_completion)
      complete -F _greb_completion greb
    fi
  fi
  # git-fsck-and-gc
  if [ "$gitfd" ]; then
    exec {gitfd}>&-
    unset gitfd
  fi
  local dir=$(readlink -e "$(git rev-parse --git-dir)")
  local sum="$(md5sum <<< "$dir" | cut -f 1 -d ' ')"
  local lock=~/var/lock/elock-git-"$sum"
  exec {gitfd}>"$lock"
  flock -s "${gitfd}"
  function wogitfd() {
    {gitfd}>&- "$@"
  }
  # source config.sh.gpg
  local dir=$(git rev-parse --git-dir 2>/dev/null)
  if [ -f "$dir"/config.sh.gpg ]; then
    source <(gpg2 --batch -d "$dir"/config.sh.gpg)
  fi
  # source config.sh
  if [ -f "$dir"/config.sh ]; then
    source "$dir"/config.sh
  fi
  true
}
function cd() {
  builtin cd "$@" && postcd
}
function pushd() {
  builtin pushd "$@" && postcd
}
function popd() {
  builtin popd "$@" && postcd
}
alias i='pushd'
complete -o nospace -F _cd i
alias o='popd'
alias u='dirs -v'

# config.sh
function vi-config-sh-gpg() {
  local gitdir="$(git rev-parse --git-dir)"
  (builtin cd "$gitdir" && vi config.sh.gpg)
  if [ -f "$gitdir"/config.sh.gpg ]; then
    source <(gpg2 --batch -d "$gitdir"/config.sh.gpg)
  fi
}
function vi-config-sh() {
  local gitdir="$(git rev-parse --git-dir)"
  (builtin cd "$gitdir" && vi config.sh)
  if [ -f "$gitdir"/config.sh ]; then
    source "$gitdir"/config.sh
  fi
}

# systemctl
function pause() {
  exec {gitfd}>&- &&
    run-parts-cron -d halt -v
}
function syshalt() {
  pause &&
    ts -f &&
    sudo systemctl halt "$@" &&
    exit
}
function syspoweroff() {
  pause &&
    ts -f &&
    sudo systemctl poweroff "$@" &&
    exit
}
function sysreboot() {
  pause &&
    ts -f &&
    sudo systemctl reboot "$@" &&
    exit
}
function syssuspend() {
  pause &&
    ts -f &&
    ( killall -HUP gpg-agent; true; ) &&
    (until xscreensaver-command -lock; do systemctl --user start xscreensaver.service; done) &&
    sudo systemctl suspend "$@" &&
    exit
}
function syshibernate() {
  pause &&
    ts -f &&
    ( killall -HUP gpg-agent; true; ) &&
    (until xscreensaver-command -lock; do systemctl --user start xscreensaver.service; done) &&
    sudo systemctl hibernate "$@" &&
    exit
}
function syshybridsleep() {
  pause &&
    ts -f &&
    ( killall -HUP gpg-agent; true; ) &&
    (until xscreensaver-command -lock; do systemctl --user start xscreensaver.service; done) &&
    sudo systemctl hybrid-sleep "$@" &&
    exit
}
function xlogout() {
  pause && \
    ts -f &&
    gnome-session-quit --logout
}
function xpoweroff() {
  pause && \
    ts -f &&
    gnome-session-quit --power-off
}
function xreboot() {
  pause && \
    ts -f &&
    gnome-session-quit --reboot
}

# down
function down() {
  yes "|" | head -$((LINES - 3)) && echo v
}
function down() {
  echo -e "\\033[6n"
  read -s -d R foo
  lines=$((LINES - $(echo "$foo" | cut -d \[ -f 2 | cut -d \; -f 1) - 3))
  while [ $lines -gt 0 ]; do
    echo \|
      lines=$((lines - 1))
  done
  echo v
}
function clear() {
  command clear
  down
}

# loops
function reuntil() {
  seconds="$1" && shift || seconds=5
  until $(history -p !!); do
    sleep "$seconds"
  done
}
function rewhile() {
  seconds="$1" && shift || seconds=5
  while $(history -p !!); do
    sleep "$seconds"
  done
}
function iwhile() {
  while echo && inotifywait -q -e create -e modify -e move -e delete -r . --exclude ".*\\.sw.$"; do
    eval "$*"
    sleep 1
  done
}

# mail
function mailnow() {
  echo "$*" | mail -s "$*" $(whoami)
}
function maillater() {
  minutes="$1" && shift || minutes=1
  echo echo \""$*"\" \| mail -s \""$*"\" $(whoami) | at now + "$minutes" minute
}

# ts
function ts() {
  command ts "$@"
  local s=$?
  (builtin cd ~ && git commit -m .ts.json .ts.json &>/dev/null)
  return $s
}

# notify-send
countdown(){
  date1=$((`date +%s` + $1));
  while [ "$date1" -ge `date +%s` ]; do
    echo -ne "$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)\r";
    sleep 0.1
  done
  notify-send "$@"
}
stopwatch(){
  date1=`date +%s`;
  while true; do
    echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r";
    sleep 0.1
  done
}

# set PATH
if [ -d ~/usr/local/bin ]; then
  PATH=~/usr/local/bin:"$PATH"
fi
if [ -d ~/bin/games ] ; then
  PATH=~/bin/games:"$PATH"
fi
if [ -d ~/bin ] ; then
  PATH=~/bin:"$PATH"
fi

# set CDPATH
export CDPATH=.:~:~/src:~/lib/go/src:~/lib/go/src/github.com/daniel-fanjul-alcuten

# vim configuration
if type vim &>/dev/null; then
  export EDITOR=$(which vim)
fi
set -o vi

# go configuration
if [ "$(uname)" = Darwin ]; then
  GOMAXPROCS=$(sysctl -n hw.ncpu)
else
  GOMAXPROCS=$(grep ^processor /proc/cpuinfo | wc -l)
fi
function gd() {
  go doc "$@" | less -F
}
function gf() {
  go fmt "$@" ./...
}
function gb() {
  go build "$@" ./...
}
function gbm() {
  go build -gcflags -m ./...
}
function gv() {
  go vet ./...
}
function gi() {
  go install "$@" ./...
}
function gt() {
  go test "$@" ./...
}
function gtt() {
  go clean -cache ./... && gt "$@"
}
function gtc() {
  for p in $(go list ./...); do
    local tmp1=$(tempfile)
    if ! go test -coverprofile "$tmp1" "$@" "$p"; then
      command rm "$tmp1"
      return 1
    fi
    command rm "$tmp1"
  done
}
function gtcc() {
  for p in $(go list ./...); do
    local tmp1=$(tempfile)
    if ! go test "$@" -coverprofile "$tmp1" "$p"; then
      command rm "$tmp1"
      return 1
    fi
    local tmp2=$(tempfile -s .html)
    if ! go tool cover -html "$tmp1" -o "$tmp2"; then
      command rm "$tmp1"
      return 1
    fi
    command rm "$tmp1"
    xdg-open $tmp2
  done
}
function gtn() {
  f=$(tempfile)
  g=$(tempfile)
  ln -sf ~/usr/share/images/red.gif "$g"
  (gt "$@" && ln -sf ~/usr/share/images/blue.gif "$g") |& command tee "$f"
  command notify-send -i "$g" gt -- "$(cat "$f")"
  command rm "$f"
}
function gtni() {
  if [ "$STY" ]; then
    screen -X title gtni
    screen -X number 99
  fi
  gtn -failfast -timeout 1m "$@" && gi
  inotifywait -m -r -e create -e close_write -e delete --format '%e %f' . \
    |& grep --line-buffered '.go$' \
    | while read line; do echo; echo "$line"; while read -t 0.1 line; do echo "$line"; done; gtn -failfast -timeout 1m "$@" && gi; done;
}

# wcd configuration
if type wcd.exec &>/dev/null; then
  function wcd() {
    mkdir -p ~/var
    wcd.exec -G ~/var "$@"
    . ~/var/wcd.go
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
  function wcd() {
    for dir in ~/src/* ~/lib/go/src/github.com/daniel-fanjul-alcuten/*; do
      if local dirname=$(basename "$dir") && grep "^$1" &>/dev/null <<<$dirname; then
        cd "$dir" && echo "$PWD" && return 0
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

# aws configuration
if type aws_completer &>/dev/null; then
  complete -C $(which aws_completer) aws
fi

# maven configuration
function mi() {
  mvn install -DskipTests=true "$@"
}
function mci() {
  mvn clean install -DskipTests=true "$@"
}
function mt() {
  mvn test -DskipTests=false "$@"
}
function mct() {
  mvn clean test -DskipTests=false "$@"
}
function mit() {
  mvn install -DskipTests=false "$@"
}
function mcit() {
  mvn clean install -DskipTests=false "$@"
}
function mj() {
  mvn jetty:run -DskipTests=true "$@"
}
function mcj() {
  mvn clean jetty:run -DskipTests=true "$@"
}
function mij() {
  mvn install jetty:run -DskipTests=true "$@"
}
function mcij() {
  mvn clean install jetty:run -DskipTests=true "$@"
}
function mb() {
  mvn cobertura:cobertura && xdg-open target/site/cobertura/index.html
}
function mcb() {
  mvn clean cobertura:cobertura && xdg-open target/site/cobertura/index.html
}

# gpg
export GPG_TTY=$(tty)
function gpg-connect-agent-updatestartuptty() {
  gpg-connect-agent updatestartuptty /bye
}
function gpg-connect-agent-reloadagent() {
  gpg-connect-agent reloadagent /bye
}

# systemctl
for file in ~/.config/systemd/{user,system}/*; do
  target=$(basename "$file")
  if [ -f ~/.config/systemd/user/"$target" ]; then
    if [ -f ~/.config/systemd/system/"$target" ]; then
      eval -- "+$target()" \{ sudo systemctl start "$target" '&&' systemctl --user start "$target"\; \}
      eval -- "-$target()" \{ sudo systemctl stop "$target" '&&' systemctl --user stop "$target"\; \}
    else
      eval -- "+$target()" \{ systemctl --user start "$target"\; \}
      eval -- "-$target()" \{ systemctl --user stop "$target"\; \}
    fi
  elif [ -f ~/.config/systemd/system/"$target" ]; then
    eval -- "+$target()" \{ sudo systemctl start "$target"\; \}
    eval -- "-$target()" \{ sudo systemctl stop "$target"\; \}
  fi
done
for target in boinccmd-{run,gpu,network}@{never,auto,always}.service; do
  eval -- "+$target()" \{ systemctl --user start "$target"\; \}
  eval -- "-$target()" \{ systemctl --user stop "$target"\; \}
done
for service in $(grep -h \\.service ~/.config/systemd/system/*.target | sed 's/^Wants=//' | sort -u); do
  eval -- "+$service()" \{ sudo systemctl start "$service"\; \}
  eval -- "-$service()" \{ sudo systemctl stop "$service"\; \}
done
eval -- "+daemon-reload()" \{ sudo systemctl daemon-reload '&&' systemctl --user daemon-reload\; \}
unset target

# sysctl
function swappiness() {
  if [ "$1" ]; then
    sudo sysctl -w vm.swappiness="$1"
  else
    sudo sysctl vm.swappiness
  fi
}

# kubectl
if type kubectl &>/dev/null; then
  source <(kubectl completion bash)
fi

# crawl
export CRAWL_DIR=~/.crawl

# down
down

# sudo
sudo -v

# fs && ssh
gpg-connect-agent updatestartuptty /bye >/dev/null
if type fs &>/dev/null; then
  source <(fs --bash _fs_completion)
  complete -F _fs_completion fs
fi
ssh localhost true

# pal
if type pal &>/dev/null; then
  pal -r 7 -c 1
fi

# gvm
[ -s ~/.gvm/scripts/gvm ] && source ~/.gvm/scripts/gvm
if [ "$GOPATH" ]; then
  GOPATH=~/lib/go:"$GOPATH"
else
  GOPATH=~/lib/go
fi

# from
if type from &>/dev/null; then
  from -c
fi

# postcd
postcd
