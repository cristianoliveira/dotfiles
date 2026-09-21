#!/usr/bin/env bash
# Adjust screen brightness and notify the new level.
# Usage: notify-brightness.sh <up|down>
set -euo pipefail

case "${1:-}" in
  up)   xbacklight -inc 10 ;;
  down) xbacklight -dec 10 ;;
  *)    echo "usage: $0 up|down" >&2; exit 1 ;;
esac

bri="$(xbacklight -get | cut -d. -f1)"

notify-send -h "string:x-canonical-private-synchronous:brightness" \
            -h "int:value:${bri}" \
            -i display-brightness \
            "Brightness" "${bri}%"
