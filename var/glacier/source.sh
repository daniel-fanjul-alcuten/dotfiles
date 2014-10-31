#!/bin/bash

glacierdir=~/var/glacier
eval $(gpg -d $glacierdir/credentials.gpg)

add-to-glacier() {
  echo | gpg -es -r dfanjul-vault -u dfanjul-vault >/dev/null
  file=$1 && shift || { echo file?; return 1; }
  set -o pipefail
  set -x
  if ! command nice sha512sum "$file" | tee -a $glacierdir/sha512; then
    set +x
    return 2
  fi
  if ! gpg -es -r dfanjul-vault -u dfanjul-vault "$file"; then
    set +x
    return 1
  fi
  tmpfile=add-to-glacier-$RANDOM
  if ! command nice sha512sum "$file".gpg | tee -a $glacierdir/sha512 $tmpfile; then
    command rm -f "$tmpfile"
    set +x
    return 3
  fi
  if ! sha=$(command sed -e 's/ .*//' "$tmpfile"); then
    command rm -f "$tmpfile"
    set +x
    return 4
  fi
  if ! command rm -f "$tmpfile"; then
    set +x
    return 5
  fi
  if ! archiveId=$(command nice glacier multipart run eu-west-1 dfanjul "$file".gpg 16 "$sha"); then
    beep -f 300 -r 3 -l 150 -n -f 200 -l 400
    glacier multipart print "$file".gpg
    set +x
    return 7
  fi
  if ! echo "$sha  $archiveId" >> $glacierdir/index; then
    set +x
    return 8
  fi
  beep -f 1000 -r 2 -n -r 7 -l 10 -f 600
  set +x
}
