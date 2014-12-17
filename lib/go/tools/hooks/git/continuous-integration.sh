#!/bin/bash
set -e

url="git@github.com:$CENSORED"
ref="refs/heads/master"
while getopts 'u:p:r:i:o:fm:gc' opt; do
  case $opt in
    u) url="$OPTARG";;
    p) pkg="$OPTARG";;
    r) ref="$OPTARG";;
    i) gitdir="$OPTARG";;
    o) godir="$OPTARG";;
    f) fetch=true;;
    m) gvm="$OPTARG";;
    g) update=true;;
    c) notests=true;;
    *) exit 1
  esac
done
shift $((OPTIND - 1))

if [ -z "$pkg" ]; then
  pkg="$url"
  pkg="${pkg##git@}"
  pkg="${pkg##http://}"
  pkg="${pkg##https://}"
  pkg="${pkg/://}"
fi

if [ -z "$godir" ]; then
  if [ -z "$gitdir" ]; then
    godir="$(mktemp -d 2>/dev/null || mktemp -d -t 'continuous-integration-test')"
    gitdir="$godir/src/$pkg"
  else
    godir="$gitdir"
    godir="${godir%%/}"
    tmp="$godir"
    godir="${godir%%src/$pkg}"
    if [ "$godir" = "$tmp" ]; then
      echo "$gitdir does not end with src/$pkg"
      exit 2
    fi
  fi
elif [ -z "$gitdir" ]; then
  gitdir="$godir/src/$pkg"
fi

run() {
  echo "$ $@"
  "$@"
}

if [ ! -d "$gitdir" ]; then
  run git init "$gitdir"
  fetch=true
fi
run cd "$gitdir"
if [ "$fetch" ]; then
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

export GOPATH="$godir"
run go env
pkgspec="$pkg/..."
run go list "$pkgspec"
run go get -v "$pkgspec"
if [ "$update" ]; then
  run go get -v -u \
    $(go list -f '{{join .Deps "\n"}}' "$pkgspec" |\
      sort -u |\
      grep -v "^$pkg" |\
      xargs go list -f '{{if not .Standard}}{{.ImportPath}}{{end}}')
fi
run go install -v "$pkgspec"
if [ -z "$notests" ]; then
  run go test -v -p 1 "$pkgspec"
fi
if run go get -v golang.org/x/tools/cmd/vet; then
  if [ "$update" ]; then
    run go get -v -u golang.org/x/tools/cmd/vet
  fi
  run go vet "$pkgspec"
fi
if run go get -v github.com/golang/lint/golint; then
  if [ "$update" ]; then
    go get -v -u github.com/golang/lint/golint
  fi
  run "$godir/bin/golint" "$pkgspec" || true
fi
