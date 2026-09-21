#!/usr/bin/env bash
# Toggle Wi-Fi radio and notify the new state.
set -euo pipefail

if nmcli radio wifi | grep -q enabled; then
  nmcli radio wifi off
  text="Off"; icon="network-wireless-off"
else
  nmcli radio wifi on
  text="On"; icon="network-wireless"
fi

notify-send -h "string:x-canonical-private-synchronous:wifi" \
            -i "$icon" \
            "Wi-Fi" "$text"
