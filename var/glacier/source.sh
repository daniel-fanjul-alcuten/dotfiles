#!/bin/bash

glacierdir=~/var/glacier
alias gpg="command gpg --homedir=$glacierdir/.gnupg"
eval $(gpg -d $glacierdir/credentials.gpg)

add-to-glacier() {
  file=$1 && shift || { echo file?; return 1; }
  set -o pipefail
  set -x
  if ! command sha512sum "$file" | tee -a $glacierdir/sha512; then
    set +x
    return 2
  fi
  if ! gpg -es -r dfanjul-vault "$file"; then
    set +x
    return 1
  fi
  tmpfile=add-to-glacier-$RANDOM
  if ! command sha512sum "$file".gpg | tee -a $glacierdir/sha512 $tmpfile; then
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
  if ! archiveId=$(glacier multipart run eu-west-1 dfanjul "$file".gpg 64 "$sha"); then
    glacier multipart print "$file".gpg
    set +x
    return 7
  fi
  if ! echo "$sha  $archiveId" >> $glacierdir/index; then
    set +x
    return 8
  fi
  set +x
}
