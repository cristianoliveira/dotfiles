#!/usr/bin/env bash

# This script cycles through windows of the same application (similar to macOS Mod+`)
# It finds all windows with the same app_id or class as the currently focused window
# and focuses the next one in the list.

set -e

DEBUG="${DEBUG:-false}"

log() {
    if [ "$DEBUG" = "true" ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Get the sway tree
TREE=$(swaymsg -t get_tree)
log "Retrieved sway tree"

# Get the currently focused window
FOCUSED=$(echo "$TREE" | jq -r '
  recurse(.nodes[]?, .floating_nodes[]?) 
  | select(.focused == true)')

if [ -z "$FOCUSED" ] || [ "$FOCUSED" = "null" ]; then
    echo "Could not find focused window"
    exit 1
fi

log "Focused window JSON: $FOCUSED"

# Extract app identifier - prefer app_id, fall back to window_properties.class
APP_ID=$(echo "$FOCUSED" | jq -r '.app_id // empty')
CLASS=$(echo "$FOCUSED" | jq -r '.window_properties.class // empty')

log "app_id='$APP_ID', class='$CLASS'"

if [ -n "$APP_ID" ] && [ "$APP_ID" != "null" ]; then
    IDENTIFIER="$APP_ID"
    IDENTIFIER_TYPE="app_id"
elif [ -n "$CLASS" ] && [ "$CLASS" != "null" ]; then
    IDENTIFIER="$CLASS"
    IDENTIFIER_TYPE="class"
else
    echo "Focused window has no app_id or class"
    exit 1
fi

log "Using $IDENTIFIER_TYPE='$IDENTIFIER'"

# Get all windows with the same identifier
WINDOWS=$(echo "$TREE" | jq -r --arg type "$IDENTIFIER_TYPE" --arg ident "$IDENTIFIER" '
  [
    recurse(.nodes[]?, .floating_nodes[]?) 
    | select(.[$type] == $ident)
    | select(.type == "con" or .type == "floating_con")
    | select(.scratchpad_state == "none" or .scratchpad_state == null)
    | .id
  ] | unique')

log "Windows JSON array: $WINDOWS"

if [ -z "$WINDOWS" ] || [ "$WINDOWS" = "[]" ]; then
    echo "No other windows found with $IDENTIFIER_TYPE=$IDENTIFIER"
    exit 1
fi

# Parse window IDs into array
WINDOW_IDS=$(echo "$WINDOWS" | jq -r '.[]')
readarray -t ID_ARRAY <<< "$WINDOW_IDS"

log "Found ${#ID_ARRAY[@]} windows: ${ID_ARRAY[*]}"

# Get current focused window ID
CURRENT_ID=$(echo "$FOCUSED" | jq -r '.id')
log "Current window ID: $CURRENT_ID"

# Find current index
CURRENT_INDEX=-1
for i in "${!ID_ARRAY[@]}"; do
    if [ "${ID_ARRAY[$i]}" = "$CURRENT_ID" ]; then
        CURRENT_INDEX=$i
        break
    fi
done

if [ $CURRENT_INDEX -eq -1 ]; then
    echo "Current window not found in the list"
    exit 1
fi

log "Current index: $CURRENT_INDEX"

# Calculate next index (wrap around)
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#ID_ARRAY[@]} ))

# If there's only one window, do nothing
if [ ${#ID_ARRAY[@]} -eq 1 ]; then
    log "Only one window with $IDENTIFIER_TYPE=$IDENTIFIER, nothing to do"
    exit 0
fi

# Focus the next window
NEXT_ID="${ID_ARRAY[$NEXT_INDEX]}"
log "Focusing window $NEXT_ID (index $NEXT_INDEX)"
swaymsg "[con_id=$NEXT_ID] focus"

echo "Focused window $NEXT_ID ($IDENTIFIER_TYPE=$IDENTIFIER)"