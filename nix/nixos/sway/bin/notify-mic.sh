#!/usr/bin/env bash
# Toggle the default source (mic) mute and notify the new state.
set -euo pipefail

wpctl set-mute @DEFAULT_SOURCE@ toggle

out="$(wpctl get-volume @DEFAULT_SOURCE@)"
if grep -q "MUTED" <<< "$out"; then
  text="Muted"; icon="microphone-sensitivity-muted"
else
  text="Unmuted"; icon="microphone-sensitivity-high"
fi

notify-send -h "string:x-canonical-private-synchronous:mic" \
            -i "$icon" \
            "Microphone" "$text"
