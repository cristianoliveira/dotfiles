#!/usr/bin/env bash
# copy-to-command.sh
#
# Receives the tmux copy-mode selection on stdin, opens it in $EDITOR (nvim/vim)
# inside a tmux popup for editing, and runs the saved result as a shell command
# in the target pane.
#
# Invoked from copy-mode-vi key binding (x). See mappings/tmux-copy-command.conf
#
# Args/env:
#   $1         - target pane id (passed from the keybind as #{pane_id})
#   EDITOR     - editor to use (default: nvim, fallback: vim)
#   stdin      - the tmux copy-mode selection (piped by copy-pipe-and-cancel)

set -uo pipefail

# --- logging (errors only; tail ~/.dotfiles/tmux/.tmp/logs/copy-to-command.log) -
aw_raw="${AGENT_WORKSPACE:-$HOME/.dotfiles/tmux/.tmp}"
log_dir="${aw_raw%/}/logs"
mkdir -p "$log_dir" 2>/dev/null
log_file="$log_dir/copy-to-command.log"
log() { echo "[$(date '+%H:%M:%S')] $*" >>"$log_file"; }

editor="${EDITOR:-nvim}"
command -v "$editor" >/dev/null 2>&1 || editor="vim"
command -v "$editor" >/dev/null 2>&1 || editor="vi"

target_pane="${1:-}"
if [[ -z "$target_pane" ]]; then
	log "ERROR: no target pane id passed (expected as \$1 from #{pane_id})"
	exit 1
fi

# Stage the selection for editing.
tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/tmux-c2c.XXXXXX")"
cmd_file="$tmpdir/command.sh"
trap 'rm -rf "$tmpdir"' EXIT

# read returns non-zero on EOF without a NUL terminator — the normal case here.
selection=""
IFS= read -r -d '' selection || true
printf '%s' "$selection" >"$cmd_file"

# Open the editor in a popup. -E makes tmux wait for the popup to close before
# continuing, so we can read the file back afterwards.
if ! tmux popup -E -w 80% -h 60% -b rounded \
	"$editor -c 'set filetype=sh' '$cmd_file'"; then
	log "ERROR: tmux popup failed (pane=$target_pane)"
	exit 1
fi

# Nothing saved / empty command -> bail quietly.
[[ -s "$cmd_file" ]] || exit 0

# Run the edited text as a shell command in the target pane.
# send-keys + Enter lands it in the user's shell/history.
if ! tmux send-keys -t "$target_pane" "$(cat "$cmd_file")" Enter; then
	log "ERROR: tmux send-keys failed (pane=$target_pane)"
	exit 1
fi
