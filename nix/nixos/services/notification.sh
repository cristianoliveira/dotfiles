#!/bin/sh

set -e

## Script that keep track of the battery status and 
## Calls swayng when the battery is below 10%
## Suspend the system when the battery is below 5%


while true; do
  battery_status=$(cat /sys/class/power_supply/BAT0/status)
  battery_capacity=$(cat /sys/class/power_supply/BAT0/capacity)

  echo "[DEBUG] Battery status: $battery_status"
  echo "[DEBUG] Battery capacity: $battery_capacity"

  if [ $battery_capacity -lt 5 ] && [ $battery_status == "Discharging" ]; then
      echo "Battery is below 5%"
      swaymsg "output * dpms off"
      swaymsg "exec systemctl suspend"
  fi

  if [ $battery_capacity -lt 10 ] && [ $battery_status == "Discharging" ]; then
      echo "Battery is below 10%"
      swaynag -t warning -m "Battery is below 10%" -B "Suspend" "systemctl suspend"
  fi

  sleep 60
done
