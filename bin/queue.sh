#!/bin/bash

QUEUE_NAME=$1
COMMAND=$2
VALUE=$3

QUEUE="$HOME/.local/state/queue-$QUEUE_NAME"
touch "$QUEUE" 2>/dev/null || true

if [ -z "$COMMAND" ]; then
  echo "Usage: $0 [queue-name] <push|pop|clear|shift> [value]"
  exit 1
fi

if [ "$COMMAND" = "push" ]; then
  # Push IDs of moved windows
  echo "$VALUE" >> "$QUEUE"
  exit 0
fi

if [ "$COMMAND" = "pop" ]; then
  # Pop oldest window ID and summon it back
  if [ -s "$QUEUE" ]; then
    wid=$(head -n1 "$QUEUE")
    tail -n +2 "$QUEUE" > "$QUEUE.tmp" && mv "$QUEUE.tmp" "$QUEUE"
    echo "$wid"
  else
    echo "__EMPTY__"
    exit 1
  fi
fi

if [ "$COMMAND" = "clear" ]; then
  rm "$QUEUE"
  exit 0
fi

if [ "$COMMAND" = "shift" ]; then
  if [ -s "$QUEUE" ]; then
    wid=$(tail -n1 "$QUEUE")
    head -n -1 "$QUEUE" > "$QUEUE.tmp" && mv "$QUEUE.tmp" "$QUEUE"
    echo "$wid"
  else
    echo "__EMPTY__"
    exit 1
  fi
fi
