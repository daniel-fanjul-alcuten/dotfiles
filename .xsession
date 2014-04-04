#!/bin/sh

# umask
umask 077

# agents
#eval `gpg-agent --daemon`
eval `gnome-keyring-daemon`

# background
xset -b
hsetroot -solid \#000000

# gnome
nm-applet &
mail-notification &
gnome-screensaver &

# awesome
exec awesome
