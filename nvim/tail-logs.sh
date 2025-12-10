#!/bin/sh

CMD=$1

# Truncate
if [ "$CMD" == "truncate" ]; then
  find ~/.local/state/nvim ~/.local/share/nvim ~/.cache/nvim ~/.config/nvim -name "*.log" -o -name "log" -type d 2>/dev/null | xargs truncate -s 0
  exit
fi

tail -f $(find ~/.local/state/nvim ~/.local/share/nvim ~/.cache/nvim ~/.config/nvim -name "*.log" -o -name "log" -type d 2>/dev/null)
