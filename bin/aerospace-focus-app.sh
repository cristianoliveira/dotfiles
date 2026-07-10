#!/usr/bin/env bash
# aerospace-focus-app.sh — focus a window by app-name (regex) and optional
# window-title (regex) using PURE aerospace (no aerospace-scratchpad / marks / IPC socket).
#
# Native `aerospace focus` only takes --window-id / direction / DFS index, so we
# resolve the id via `list-windows --all` then `focus --window-id`. `focus --window-id`
# auto-switches the workspace on the target monitor (verified in aerospace source).
#
# Exits non-zero when no window matches, so it composes in `||` fallback chains:
#   aerospace-focus-app.sh 'zoom.us|Teams' \
#     || aerospace-focus-app.sh 'Google' 'Meet'
#
# Limitation: cannot focus minimized / native-hidden / native-fullscreen windows
# (aerospace returns false for those). For those, keep using aerospace-scratchpad show.
#
# Usage:
#   aerospace-focus-app.sh <app-name-regex> [window-title-regex]
set -euo pipefail

app_re="${1:?usage: aerospace-focus-app.sh <app-name-regex> [window-title-regex]}"
title_re="${2:-}"

id=$(aerospace list-windows --all --json \
  | jq -r --arg app "$app_re" --arg title "$title_re" '
      [ .[]
        | select(."app-name" | test($app; "i"))
        | select(if $title == "" then true
                 else (."window-title" // "") | test($title; "i") end)
      ] | .[0]."window-id" // empty')

if [ -z "${id:-}" ]; then
  echo "aerospace-focus-app: no window matching app=/$app_re/ title=/$title_re/" >&2
  exit 1
fi

exec aerospace focus --window-id "$id"
