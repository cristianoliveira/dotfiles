#!/bin/sh

set -e

swayidle -w \
  timeout 180 'swaylock -f' \
  timeout 60 'swaymsg "output * power off"' \
  resume 'swaymsg "output * power on"' \
  before-sleep 'swaylock -f'
