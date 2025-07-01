#!/bin/sh

set -e

pkill -x swayidle || true

swayidle -w \
  timeout 480 'swaylock -f' \
  timeout 260 'swaymsg "output * power off"' \
  resume 'swaymsg "output * power on"' \
  before-sleep 'swaylock -f'
