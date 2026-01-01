#!/usr/bin/env bash

# This script is used to mimic stack-like behavior where you can jump back to the
# previous window with mod + tab

STACK_FILE="${HOME}/.local/state/sway-focus-stack.txt"

# Ensure state directory exists
mkdir -p "$(dirname "$STACK_FILE")"

# Get the currently focused container ID
CURRENT=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true) | .id')

if [ -z "$CURRENT" ] || [ "$CURRENT" = "null" ]; then
    exit 1
fi

# Helper function to create temp file
temp_file() {
    mktemp "${STACK_FILE}.XXXXXX"
}

# Helper function to update stack with current window at top
update_stack_with_current() {
    local temp=$(temp_file)
    {
        echo "$CURRENT"
        grep -v "^${CURRENT}$" "$STACK_FILE" 2>/dev/null || true
    } | head -20 > "$temp"
    mv "$temp" "$STACK_FILE"
}

# Read stack file
if [ ! -f "$STACK_FILE" ] || [ ! -s "$STACK_FILE" ]; then
    # No stack file or empty, create with current window
    echo "$CURRENT" > "$STACK_FILE"
    exit 0
fi

# Get the first two entries from stack
STACK_TOP=$(head -1 "$STACK_FILE")
STACK_SECOND=$(sed -n '2p' "$STACK_FILE")

# If stack top doesn't match current window, tracker might be out of sync.
# Update stack with current window at top.
if [ "$STACK_TOP" != "$CURRENT" ]; then
    update_stack_with_current
    STACK_TOP="$CURRENT"
    STACK_SECOND=$(sed -n '2p' "$STACK_FILE")
fi

# If we have a second entry and it's different from current, focus it and rotate stack
if [ -n "$STACK_SECOND" ] && [ "$STACK_SECOND" != "$CURRENT" ]; then
    # Check if the second entry still exists
    EXISTS=$(swaymsg -t get_tree | jq -r "recurse(.nodes[]?, .floating_nodes[]?) | select(.id == $STACK_SECOND) | .id")
    if [ "$EXISTS" = "$STACK_SECOND" ]; then
        # Focus the previous window
        swaymsg "[con_id=$STACK_SECOND] focus"
        
        # Rotate stack: swap first and second entries
        local temp=$(temp_file)
        {
            echo "$STACK_SECOND"
            echo "$STACK_TOP"
            tail -n +3 "$STACK_FILE" 2>/dev/null || true
        } | head -20 > "$temp"
        mv "$temp" "$STACK_FILE"
        exit 0
    else
        # Second entry no longer exists, remove it from stack
        local temp=$(temp_file)
        grep -v "^${STACK_SECOND}$" "$STACK_FILE" 2>/dev/null > "$temp" || true
        mv "$temp" "$STACK_FILE"
    fi
fi

# If we couldn't switch to a previous window, ensure current is at top of stack
if [ "$STACK_TOP" != "$CURRENT" ]; then
    update_stack_with_current
fi