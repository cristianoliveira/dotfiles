#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands

# every 30m, save the current tree
#

service_count=$(pgrep -f sway-save-tree.sh | wc -l)
if [ $service_count -gt 2 ]; then
  echo "sway-save-tree.sh is already running"
  exit 1
fi

while true; do
  swaymsg -t get_tree > $HOME/.local/state/sway-tree.json
  sleep 1800
done
