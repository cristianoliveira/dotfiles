#!/usr/bin/env bash
# kill-port.sh
#
# Opens a tmux popup: lists all listening TCP ports with process details,
# lets you fzf-filter in one step (type a port, PID, or process name), and
# kills the selected process(es).  TAB = select multiple, Enter = kill.
#
# Works on macOS and Linux.

set -uo pipefail

# --- list all listening TCP ports with process details -------------------
lines="$(lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null \
  | awk 'NR>1 && $9 ~ /:/ { pid=$2; port=$9; gsub(/.*:/, "", port); if (port ~ /^[0-9]+$/) print pid, port }' \
  | sort -u \
  | while read -r pid port; do
    cmd="$(basename "$(ps -p "$pid" -o comm= 2>/dev/null)" 2>/dev/null)"
    args="$(ps -p "$pid" -o args= 2>/dev/null | head -c 100 | tr '\n' ' ')"
    printf "%s:%-6s  %-20s  %s\n" "$pid" "$port" "$cmd" "$args"
  done)"

if [[ -z "$lines" ]]; then
  echo "no listening TCP ports found"
  sleep 1
  exit 0
fi

# --- fzf picker ----------------------------------------------------------
count="$(echo "$lines" | wc -l | tr -d ' ')"
header="Kill process ($count ports, TAB=multi, Enter=kill)"

selected="$(echo "$lines" \
  | fzf --multi --header="$header" --prompt="filter> " \
    --ansi --delimiter=' ' --nth=2.. 2>/dev/null || true)"

if [[ -z "$selected" ]]; then
  echo "cancelled"
  sleep 0.5
  exit 0
fi

# --- extract PIDs and kill -----------------------------------------------
kill_list=()
while IFS= read -r line; do
  kill_list+=("${line%%:*}")
done <<<"$selected"

echo "killing PIDs: ${kill_list[*]}"
if ! kill -9 "${kill_list[@]}" 2>/tmp/c2c-kill-err.log; then
  echo "kill failed (need sudo?):"
  cat /tmp/c2c-kill-err.log
  sleep 2
  exit 1
fi
echo "done"
sleep 0.5
