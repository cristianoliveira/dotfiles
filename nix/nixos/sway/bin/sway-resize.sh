#!/usr/bin/env bash

## This script receives

ARG="$1"
if [[ -z "$ARG" ]]; then
  echo "Usage: $0 [w30|w50|w75|w100|h30|h50|h75|h100]"
  exit 1
fi


if [[ "$ARG" != w* && "$ARG" != h* ]]; then
  echo "Invalid argument: $ARG"
  exit 1
fi

# Split the argument into direction and percentage
DIR="${ARG:0:1}"
PERCENT="${ARG:1}"

if ! [[ "$PERCENT" =~ ^[0-9]+$ ]] || (( PERCENT <= 0 || PERCENT > 100 )); then
  echo "Invalid percentage: $PERCENT"
  exit 1
fi

# GEt the current output size
CURRENT_SIZE=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.rect.width) \(.rect.height)"')
if [[ -z "$CURRENT_SIZE" ]]; then
  echo "No focused window found."
  exit 1
fi

# Extract current width and height
CURRENT_WIDTH=$(echo "$CURRENT_SIZE" | awk '{print $1}')
CURRENT_HEIGHT=$(echo "$CURRENT_SIZE" | awk '{print $2}')
# Calculate new size based on the direction
#
if [[ "$DIR" == "w" ]]; then
  NEW_WIDTH=$((CURRENT_WIDTH * PERCENT / 100))
  NEW_HEIGHT=$CURRENT_HEIGHT
elif [[ "$DIR" == "h" ]]; then
  NEW_WIDTH=$CURRENT_WIDTH
  NEW_HEIGHT=$((CURRENT_HEIGHT * PERCENT / 100))
fi

# Resize the focused window
swaymsg resize set "$NEW_WIDTH" "$NEW_HEIGHT"
