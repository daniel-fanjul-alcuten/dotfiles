#!/bin/bash
set -e

ref='HEAD'
while getopts 'o:p:r:i:d:fv:uc' opt; do
  case $opt in
    o) url="$OPTARG";;
    p) pkg="$OPTARG";;
    r) ref="$OPTARG";;
    i) gitdir="$OPTARG";;
    d) godir="$OPTARG";;
    f) fetch=true;;
    v) gvm="$OPTARG";;
    u) update="-u";;
    c) notests=true;;
    *) exit 16
  esac
done
shift $((OPTIND - 1))

if [ -z "$pkg" ]; then
  if [ -z "$url" ]; then
    echo "\$url or \$pkg not defined" 2>&1
    exit 17
  fi
  pkg="$url"
  if [[ "$pkg" =~ ^git@ ]]; then
    pkg="${pkg##git@}"
    pkg="${pkg/://}"
  elif [[ "$pkg" =~ ^http:// ]]; then
    pkg="${pkg##http://}"
    pkg="${pkg/://}"
  elif [[ "$pkg" =~ ^https:// ]]; then
    pkg="${pkg##https://}"
    pkg="${pkg/://}"
  else
    echo "\$pkg not defined" 2>&1
    exit 18
  fi
fi

if [ -z "$godir" ]; then
  if [ -z "$gitdir" ]; then
    godir="$(mktemp -d -t 'gopath-XXXXXX')"
    gitdir="$godir/src/$pkg"
  else
    godir="$gitdir"
    godir="${godir%%/}"
    tmp="$godir"
    godir="${godir%%src/$pkg}"
    if [ "$godir" = "$tmp" ]; then
      echo "$gitdir does not end with src/$pkg"
      exit 19
    fi
  fi
elif [ -z "$gitdir" ]; then
  gitdir="$godir/src/$pkg"
fi

run() {
  echo '>' "$@"
  "$@"
}

if [ ! -d "$gitdir" ]; then
  run git init "$gitdir"
  fetch=true
fi
run cd "$gitdir"
if [ "$fetch" ]; then
  if [ -z "$url" ]; then
    echo "\$url not defined" 2>&1
    exit 17
  fi
  run git fetch "$url" "$ref"
  run git checkout FETCH_HEAD
fi
run git rev-parse HEAD
run git describe --all --dirty || true

if [ "$gvm" ]; then
  [ -s ~/.gvm/scripts/gvm ] || \
    bash < <(curl -s -S -L \
    https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  source ~/.gvm/scripts/gvm
  run gvm install "$gvm"
  run gvm use "$gvm"
fi

run go version
run export GOPATH="$godir:$GOPATH"
run export GOBIN="$godir/bin"
run go env
pkgspec="$pkg/..."
run go get -v "$pkgspec"
if [ "$update" ]; then
  run go get -v $update \
    $(go list -f '{{join .Deps "\n"}}' "$pkgspec" |\
    sort -u |\
    grep -v "^$pkg" |\
    xargs go list -f '{{if not .Standard}}{{.ImportPath}}{{end}}')
fi
run go list "$pkgspec"
run go install -v "$pkgspec"
if [ -z "$notests" ]; then
  run go test -v -p 1 "$pkgspec"
fi
run go vet -v "$pkgspec"
run go fix "$pkgspec"
if run go get -v $update github.com/golang/lint/golint; then
  run "$GOBIN/golint" -set_exit_status "$pkgspec"
fi
