#!/usr/bin/env bash
# Adjust the default sink volume and notify the new level.
# Usage: notify-volume.sh <up|down|toggle-mute>
set -euo pipefail

case "${1:-}" in
  up)          wpctl set-volume @DEFAULT_SINK@ 5%+ ;;
  down)        wpctl set-volume @DEFAULT_SINK@ 5%- ;;
  toggle-mute) wpctl set-mute @DEFAULT_SINK@ toggle ;;
  *)           echo "usage: $0 up|down|toggle-mute" >&2; exit 1 ;;
esac

out="$(wpctl get-volume @DEFAULT_SINK@)"
vol="$(awk '{printf "%d", $2 * 100}' <<< "$out")"

if grep -q "MUTED" <<< "$out"; then
  text="Muted"
  icon="audio-volume-muted"
else
  text="${vol}%"
  icon="audio-volume-high"
fi

notify-send -h "string:x-canonical-private-synchronous:volume" \
            -h "int:value:${vol}" \
            -i "$icon" \
            "Volume" "$text"
