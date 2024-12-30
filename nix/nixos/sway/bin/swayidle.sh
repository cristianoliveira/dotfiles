#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands

# SWAYIDLE
#
# After 120 seconds of inactivity, swayidle will lock your screen. After 20 more
# seconds, it will turn off your displays. When you resume, swayidle will unlock
#
swayidle -w \
  timeout 180 'swaylock -f' \
  timeout 60 'pgrep swaylock && swaymsg "output * dpms off"' \
  resume 'swaymsg "output * dpms on"' \
  before-sleep 'swaylock -f'
