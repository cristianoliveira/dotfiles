#!/bin/sh

# This is for 60% keyboard where Esc and ` are on the same key
# this makes esc to be ` and capslock to be esc
REVERT="${1:-"apply"}"
if [ "$REVERT" = "revert" ]; then
  xmodmap -e "keycode 9 = Escape"
  xmodmap -e "keycode 49 = grave asciitilde"
else
  xmodmap -e "keycode 49 = Escape"
  xmodmap -e "keycode 9 = grave asciitilde"
  echo "Remapped esc and grave keys"
  echo "To revert, run: $0 revert"
fi
