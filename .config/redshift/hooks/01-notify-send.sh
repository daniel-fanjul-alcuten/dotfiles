#!/bin/bash

event="$1" && shift
old="$1" && shift
new="$1" && shift

case "$event" in
  day|night)
    exec notify-send 'Redshift' "Period is $event."
    ;;
  period-changed)
    exec notify-send 'Redshift' "Period changed from $old to $new"
    ;;
esac
