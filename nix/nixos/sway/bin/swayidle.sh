#!/bin/sh

set -e

swayidle -w \
  timeout 180 'swaylock -f' \
  timeout 60 'pgrep swaylock && swaymsg "output * dpms off"' \
  resume 'swaymsg "output * dpms on"' \
  before-sleep 'swaylock -f'
