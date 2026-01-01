#!/usr/bin/env bash

# This script subscribes to sway IPC window events and maintains a stack of focused containers.
# The stack is stored as a plain text file with one container ID per line (most recent first).

set -e

# Check if another instance is already running
if pgrep -f "sway-focus-tracker.sh" | grep -v "^$$\$" > /dev/null; then
    exit 0
fi

STACK_FILE="${HOME}/.local/state/sway-focus-stack.txt"
MAX_SIZE=20

# Ensure state directory exists
mkdir -p "$(dirname "$STACK_FILE")"

# Initialize stack file if it doesn't exist
if [ ! -f "$STACK_FILE" ]; then
    touch "$STACK_FILE"
fi

# Function to update stack with new focused container
update_stack() {
    local new_id="$1"
    
    # Read current stack
    if [ ! -s "$STACK_FILE" ]; then
        # Empty file, just add the new ID
        echo "$new_id" > "$STACK_FILE"
        return
    fi
    
    # Get current top of stack
    local current_top=$(head -1 "$STACK_FILE" 2>/dev/null || true)
    
    # If new ID is already at top, do nothing
    if [ "$current_top" = "$new_id" ]; then
        return
    fi
    
    # Create new stack: new ID first, then all existing IDs except any occurrence of new_id
    TEMP_FILE=$(mktemp "${STACK_FILE}.XXXXXX")
    {
        echo "$new_id"
        grep -v "^${new_id}$" "$STACK_FILE" || true
    } | head -$MAX_SIZE > "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$STACK_FILE"
}

# Function to get current focused container ID
get_focused_id() {
    swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true) | .id'
}

# Main loop: restart subscription if it ends (e.g., sway restart)
while true; do
    # Wait for sway IPC socket to be available
    SWAY_IPC_SOCKET="${SWAYSOCK:-$(ls /run/user/$(id -u)/sway-ipc.*.sock 2>/dev/null | head -1)}"
    if [ -z "$SWAY_IPC_SOCKET" ]; then
        sleep 5
        continue
    fi

    # Get initial focused container
    INITIAL_ID=$(get_focused_id)
    if [ -n "$INITIAL_ID" ] && [ "$INITIAL_ID" != "null" ]; then
        update_stack "$INITIAL_ID"
    fi

    # Subscribe to window events and filter for focus changes
    swaymsg -t subscribe '["window"]' | while read -r event; do
        change=$(echo "$event" | jq -r '.change')
        if [ "$change" = "focus" ]; then
            container_id=$(echo "$event" | jq -r '.container.id')
            if [ -n "$container_id" ] && [ "$container_id" != "null" ]; then
                update_stack "$container_id"
            fi
        fi
    done
    
    # If the subscription ends (sway restarted), wait and retry
    sleep 2
done