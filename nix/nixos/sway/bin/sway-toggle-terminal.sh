#!/usr/bin/env bash
set -euo pipefail

app_id="term-floating"
terminal="$HOME/.dotfiles/nix/shared/alacritty/launcher.sh"

focused_app_id=$(swaymsg -t get_tree | jq -r '.. | objects | select(.focused == true) | .app_id // empty' | head -n 1)

if [[ "$focused_app_id" == "$app_id" ]]; then
  swaymsg move scratchpad
  exit 0
fi

if swaymsg -t get_tree | jq -e --arg app_id "$app_id" '.. | objects | select(.app_id == $app_id)' >/dev/null; then
  swaymsg "[app_id=$app_id] scratchpad show; focus"
  exit 0
fi

"$terminal" "$app_id" &

for _ in {1..20}; do
  if swaymsg -t get_tree | jq -e --arg app_id "$app_id" '.. | objects | select(.app_id == $app_id)' >/dev/null; then
    swaymsg "[app_id=$app_id] move scratchpad; scratchpad show; focus"
    exit 0
  fi

  sleep 0.1
done
