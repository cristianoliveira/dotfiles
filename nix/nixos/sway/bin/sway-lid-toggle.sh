#!/usr/bin/env bash

set -euo pipefail

# Sway script to enable or disable the laptop screen when the lid is closed only
# when an external monitor is connected. That means it has more than one output
ARG=$1
LAPTOP_SCREEN="eDP-1"

# Enable the laptop screen in case it was disabled
swaymsg "output $LAPTOP_SCREEN enable"

if [ "$(swaymsg -t get_outputs | jq '[.[] | select(.active)] | length')" -gt 1 ]; then
    swaymsg "output $LAPTOP_SCREEN $ARG"
fi
