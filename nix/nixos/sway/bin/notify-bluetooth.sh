#!/usr/bin/env bash
# Toggle Bluetooth radio and notify the new state.
set -euo pipefail

if bluetoothctl show | grep -q "Powered: yes"; then
  bluetoothctl power off
  text="Off"; icon="bluetooth-disabled"
else
  bluetoothctl power on
  text="On"; icon="bluetooth-active"
fi

notify-send -h "string:x-canonical-private-synchronous:bluetooth" \
            -i "$icon" \
            "Bluetooth" "$text"
