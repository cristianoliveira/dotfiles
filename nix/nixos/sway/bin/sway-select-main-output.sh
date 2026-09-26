#!/bin/sh

set -eu

choice=$(
  swaymsg -t get_outputs |
    jq -r '.[] | select(.active) | [.name, .make, .model] | @tsv' |
    wmenu -p 'Main monitor: '
) || exit 0

output=$(printf '%s\n' "$choice" | cut -f1)
[ -n "$output" ] || exit 0

for workspace in 1 2 3 4 5 6; do
  swaymsg "workspace number $workspace output $output" >/dev/null
done

swaymsg "workspace number 1" >/dev/null
