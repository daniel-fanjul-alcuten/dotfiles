#!/bin/bash

if [ "$TERM" ]; then

  red() {
    tput setaf 1
    echo "$@"
    tput sgr0
    exit 1
  }

  green() {
    tput setaf 2
    echo "$@"
    tput sgr0
    exit 0
  }

  blue() {
    tput setaf 4
    echo "$@"
    tput sgr0
    exit 0
  }

else

  red() {
    echo "$@"
    exit 1
  }

  green() {
    echo "$@"
    exit 0
  }

  blue() {
    echo "$@"
    exit 0
  }
fi
