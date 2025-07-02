#!/bin/sh

set -e

pkill -x swayidle || true

laptop_is_off='swaymsg -t get_outputs | jq -e \".[] | select(.active == false) | select(.name == \"eDP-1\")\"'

swayidle -w \
  timeout 480 'swaylock -f' \
  timeout 260 "$laptop_is_off || swaymsg 'output * power off'"\
  resume 'swaymsg "output * power on"' \
  before-sleep 'swaylock -f'
