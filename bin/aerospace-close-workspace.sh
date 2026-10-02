#!/usr/bin/env bash
# Move every AeroSpace-managed window to workspace 1, emptying other workspaces.
set -euo pipefail

if ! command -v aerospace >/dev/null 2>&1; then
  echo "aerospace-close-workspace: aerospace CLI not found" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "aerospace-close-workspace: jq is required" >&2
  exit 1
fi

window_ids=$(aerospace list-windows --all --json | jq -r '.[] | .["window-id"]')

while IFS= read -r window_id; do
  [[ -n "$window_id" ]] || continue
  aerospace move-node-to-workspace --window-id "$window_id" 1
done <<< "$window_ids"
