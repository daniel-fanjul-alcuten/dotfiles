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
    _prompt_color "reset" "reset"
  else
    echo -ne "$output"
  fi
}
_prompt_status()
{
  local status=$?
  if [ "$status" != 0 ]; then
    _prompt_apply_color "[$status] " "status" "bold red"
  fi
}
_prompt_date() {
  _prompt_apply_color "$(date +%T)" "date" "white"
}
_prompt__hostname() {
  _prompt_apply_color " $(whoami)@$(hostname)" "hostname" "magenta"
}
_prompt_systemd() {
  local target=$({ sudo systemctl --type target; systemctl --user --type target;} | grep dfanjul | sed 's/^  *//' | cut -d ' ' -f 1 | sed 's/\.target//' | sort -u | tr '\n' ' ' | sed 's/ $//')
  if [ "$target" ]; then
    _prompt_apply_color " {$target}" "systemd" "cyan"
  fi
}
_prompt_nmcli() {
  local nmcli=$(nmcli connection show --active 2>/dev/null | tail -n +2 | grep -v 'docker0 *$' | grep -v 'tun0 *$' | cut -f 1 -d ' ' | sort | tr \\n ' ' | sed 's/ $//')
  if [ "$nmcli" ]; then
    _prompt_apply_color " <$nmcli>" "nmcli" "blue"
  fi
}
_prompt_battery()
{
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
_prompt_dirtyvm() {
  local m1=$(grep ^Dirty /proc/meminfo|cut -c 7-|sed 's/ //g')
  local m2=$(sysctl -n vm.dirty_expire_centisecs)
  local m3=$(sysctl -n vm.dirty_writeback_centisecs)
  _prompt_apply_color " $m1/$m2/$m3" "dirtyvm" "grey"
}
_prompt_git() {
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
_prompt_jobscount()
{
  local count=$(jobs -p | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    _prompt_apply_color " [$count]" "jobscount" "yellow"
  fi
}
_prompt_mail()
{
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
_complete_command() {
  COMP_LINE="command ${COMP_LINE#co }"
  COMP_POINT=$((COMP_POINT+5))
  COMP_WORDS[0]=command
  _command
}
complete -F _complete_command co
alias alert='notify-send --urgency=low -i ~/usr/share/images/$([ $? = 0 ] && echo blue || echo red).gif "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

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
    debfoster \
    docker \
    docker-compose \
    fdisk \
    iftop \
    iotop \
    service \
    shutdown \
    ; do
  alias $command="sudo $command"
done

# git hooks
mkdir -p ~/.git/hooks
cat > ~/.git/hooks/post-checkout <<-EOF
	#!/bin/bash
	chmod -f -R go-rwx ~/.{ssh,gnupg} ~/.s3ql/authinfo2
	true
EOF
cat > ~/.git/hooks/post-rewrite <<-EOF
	#!/bin/bash
	cat >/dev/null
	chmod -f -R go-rwx ~/.{ssh,gnupg} ~/.s3ql/authinfo2
	true
EOF
chmod u+x ~/.git/hooks/post-{checkout,rewrite}
if [ -f ~/usr/share/hub/etc/hub.bash_completion.sh ]; then
  source ~/usr/share/hub/etc/hub.bash_completion.sh
fi

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh /usr/bin/lesspipe)"

# functions
cd() {
  builtin cd "$@" && {
    # screen title
    local dir="$(basename "$PWD")"
    if [ "$STY" ]; then
      screen -X title "$dir"
    fi
    # task
    if type task &>/dev/null; then
      tt
    fi
    # git aliases
    if type git &>/dev/null; then
      _complete_git_aliases() {
        COMP_CWORD=$((COMP_CWORD+1))
        COMP_LINE="git $COMP_LINE"
        COMP_POINT=$((COMP_POINT+4))
        COMP_WORDS=(git "${COMP_WORDS[@]}")
        __git_wrap__git_main
      }
      for command in $(git config -l | grep ^alias\\. | cut -d= -f1 | cut -c7-)\
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
          ; do
        alias $command="git $command"
        complete -o bashdefault -o default -o nospace -F _complete_git_aliases $command
      done
      if type git-greb &>/dev/null; then
        source <(git-greb --bash _greb_completion)
        complete -F _greb_completion greb
      fi
    fi
    # source config.sh.gpg
    local dir=$(git rev-parse --git-dir)
    if [ -f "$dir"/config.sh.gpg ]; then
      source <(gpg2 --batch -d "$dir"/config.sh.gpg)
    fi
    true
  }
}
function vi-config-sh-gpg() {
  local gitdir="$(git rev-parse --git-dir)"
  (builtin cd "$gitdir" && \
    vi config.sh.gpg) && \
    if [ -f "$gitdir"/config.sh.gpg ]; then
      source <(gpg2 --batch -d "$gitdir"/config.sh.gpg)
    fi
}
clear() {
  command clear
  down
}
t() {
  command task "$@"
  local s=$?
  (builtin cd ~ && {
    git commit -m .task .task &>/dev/null
  })
  return $s
}
tt() {
  local dir="$(basename "$PWD" | sed s/-//g)"
  if task _tags | grep -q "^$dir$"; then
    t +"$dir" "$@"
  fi
}
tta() {
  local dir="$(basename "$PWD" | sed s/-//g)"
  t add +"$dir" "$@"
}
pause() {
  run-parts-cron -d halt -v
}
syshalt() {
  pause &&
    ts -f &&
    sudo systemctl halt "$@" &&
    exit
}
syspoweroff() {
  pause &&
    ts -f &&
    sudo systemctl poweroff "$@" &&
    exit
}
sysreboot() {
  pause &&
    ts -f &&
    sudo systemctl reboot "$@" &&
    exit
}
syssuspend() {
  pause &&
    ts -f &&
    { killall -HUP gpg-agent; true; } &&
    until xscreensaver-command -lock; do systemctl --user start xscreensaver.service; done &&
    sudo systemctl suspend "$@" &&
    exit
}
syshibernate() {
  pause &&
    ts -f &&
    { killall -HUP gpg-agent; true; } &&
    until xscreensaver-command -lock; do systemctl --user start xscreensaver.service; done &&
    sudo systemctl hibernate "$@" &&
    exit
}
syshybridsleep() {
  pause &&
    ts -f &&
    { killall -HUP gpg-agent; true; } &&
    until xscreensaver-command -lock; do systemctl --user start xscreensaver.service; done &&
    sudo systemctl hybrid-sleep "$@" &&
    exit
}
xlogout() {
  pause && \
    ts -f &&
    gnome-session-quit --logout
}
xpoweroff() {
  pause && \
    ts -f &&
    gnome-session-quit --power-off
}
xreboot() {
  pause && \
    ts -f &&
    gnome-session-quit --reboot
}
down() {
  yes "|" | head -$((LINES - 3)) && echo v
}
down() {
  echo -e "\\033[6n"
  read -s -d R foo
  lines=$((LINES - $(echo "$foo" | cut -d \[ -f 2 | cut -d \; -f 1) - 3))
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
mailnow() {
  echo "$*" | mail -s "$*" $(whoami)
}
maillater() {
  minutes="$1" && shift || minutes=1
  echo echo \""$*"\" \| mail -s \""$*"\" $(whoami) | at now + "$minutes" minute
}
complete -o nospace -F _task t
ts() {
  command ts "$@"
  local s=$?
  (builtin cd ~ && {
    git commit -m .ts.json .ts.json &>/dev/null
  })
  return $s
}
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
vi-bash-history() {
  builtin history -a &&
    command tac "$HISTFILE" |\
    command awk '!x[$0]++' |\
    command tac |\
    command sponge "$HISTFILE" &&\
    exec vi +$ ~/.bash_history
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
gf() {
  go fmt "$@" ./...
}
gb() {
  go build "$@" ./...
}
gi() {
  go install "$@" ./...
}
gt() {
  go test "$@" ./...
}
gtt() {
  for t in $(seq 23); do gt || break; done
}
gtc() {
  for p in $(go list ./...); do
    local tmp1=$(tempfile)
    if ! go test "$@" -coverprofile "$tmp1" "$p"; then
      command rm "$tmp1"
      return 1
    fi
    command rm "$tmp1"
  done
}
gtcc() {
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
gv() {
  go vet ./...
}
gtv() {
  gt "$@" && gv
}
gtvi() {
  if [ "$STY" ]; then
    screen -X title gtvi
  fi
  gtv "$@"
  inotifywait -m -r -e create -e close_write -e delete --format '%e %f' . \
    |& grep --line-buffered '.go$' \
    | while read line; do echo; echo "$line"; while read -t 0.1 line; do echo "$line"; done; gtv "$@"; done;
}
gtvn() {
  f=$(tempfile)
  g=$(tempfile)
  ln -sf ~/usr/share/images/red.gif "$g"
  { gtv "$@" && ln -sf ~/usr/share/images/blue.gif "$g"; } |& command tee "$f"
  command notify-send -i "$g" gtv -- "$(cat "$f")"
  command rm "$f"
}
gtvni() {
  if [ "$STY" ]; then
    screen -X title gtvni
    screen -X number 99
  fi
  gtvn "$@" && gi
  inotifywait -m -r -e create -e close_write -e delete --format '%e %f' . \
    |& grep --line-buffered '.go$' \
    | while read line; do echo; echo "$line"; while read -t 0.1 line; do echo "$line"; done; gtvn "$@" && gi; done;
}
gd() {
  go doc "$@" | less -F
}
gm() {
  go build -gcflags -m ./...
}

# ruby configuration
if [ -d ~/lib/ruby ]; then
  export RUBYLIB=~/lib/ruby
fi

# wcd configuration
if type wcd.exec &>/dev/null; then
  wcd() {
    mkdir -p ~/var
    wcd.exec -z 40 -G ~/var "$@"
    . ~/var/wcd.go
  }
  alias j='wcd -j'
  alias g='wcd -g'
  _wcd_complete() {
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
    local skip=
    for arg in "$@"; do
      if [ "$skip" ]; then
        skip=
      else
        case "$arg" in
          -i) skip=true;;
          -*) :;;
          *)
            screen -X title "$arg"
            break
            ;;
        esac
      fi
    done
  fi
  command ssh "$@"
  local s=$?
  local dir="$(basename "$PWD")"
  if [ "$STY" ]; then
    screen -X title "$dir"
  fi
  return $s
}

# aws configuration
if type aws_completer &>/dev/null; then
  complete -C $(which aws_completer) aws
fi

# maven configuration
# memory
export MAVEN_OPTS='-XX:MaxPermSize=256m -Xmx2048m'
# shortcuts
mi() {
  mvn install -DskipTests=true "$@"
}
mci() {
  mvn clean install -DskipTests=true "$@"
}
mt() {
  mvn test -DskipTests=false "$@"
}
mct() {
  mvn clean test -DskipTests=false "$@"
}
mit() {
  mvn install -DskipTests=false "$@"
}
mcit() {
  mvn clean install -DskipTests=false "$@"
}
mj() {
  mvn jetty:run -DskipTests=true "$@"
}
mcj() {
  mvn clean jetty:run -DskipTests=true "$@"
}
mij() {
  mvn install jetty:run -DskipTests=true "$@"
}
mcij() {
  mvn clean install jetty:run -DskipTests=true "$@"
}
mb() {
  mvn cobertura:cobertura && xdg-open target/site/cobertura/index.html
}
mcb() {
  mvn clean cobertura:cobertura && xdg-open target/site/cobertura/index.html
}

# gpg
export GPG_TTY=$(tty)
gpg-connect-agent-updatestartuptty() {
  gpg-connect-agent updatestartuptty /bye
}
gpg-connect-agent-reloadagent() {
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
type gvm &>/dev/null
if [ "$GOPATH" ]; then
  GOPATH=~/lib/go:"$GOPATH"
else
  GOPATH=~/lib/go
fi

# from
if type from &>/dev/null; then
  from -c
fi

# cd .
cd .
