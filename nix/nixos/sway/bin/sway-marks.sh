#!/usr/bin/env bash

# This script is used to set up input devices in Sway.
#

CMD="$1"

if [ -z "$CMD" ]; then
    echo "Usage: $0 mark | focus | summon | unmark"
    exit 1
fi

if [ "$CMD" = "mark" ]; then
  echo "" \
  | wofi -d -L 1 --width 280 \
         -p "Type the mark for this window: " \
  | xargs -I {} swaymsg mark "{}"

elif [ "$CMD" = "focus" ]; then
  swaymsg -t get_tree \
    | jq '.. | select(.marks? | length > 0) | "\(.marks[]) - \(.name)"' \
    | tr -d '"' \
    | wofi -d -p "Focus: " \
    | cut -c1 \
    | xargs -I {} swaymsg '[con_mark="{}"] focus'

elif [ "$CMD" = "summon" ]; then
  swaymsg -t get_tree \
    | jq '.. | select(.marks? | length > 0) | "\(.marks[]) - \(.name)"' \
    | tr -d '"' \
    | wofi -d -p "Summon: " \
    | xargs -I {} swaymsg '[con_mark="{}"] move container to workspace current'

elif [ "$CMD" = "unmark" ]; then
    swaymsg marks unmark
else
    echo "Unknown command: $CMD"
    exit 1
fi

