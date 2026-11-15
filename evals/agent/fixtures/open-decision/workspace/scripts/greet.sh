#!/bin/sh
if [ "$#" -ne 2 ] || [ "$1" != --name ]; then
  echo 'Usage: scripts/greet.sh --name NAME' >&2
  exit 2
fi
printf 'hello %s\n' "$2"
