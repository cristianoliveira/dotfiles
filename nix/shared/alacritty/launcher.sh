#!/bin/sh

classname=${1:-alacritty}

size=10.4 # linux default
if [ "$(uname)" = "Darwin" ]; then
  size=12
fi

exec /run/current-system/sw/bin/alacritty \
  --option window.opacity="0.95" \
  --option font.size=$size \
  --class "$classname"
