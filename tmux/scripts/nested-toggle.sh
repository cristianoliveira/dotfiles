#!/usr/bin/env bash
# Toggle C-a routing between the local tmux and a nested (server) tmux.
#
#   LOCAL  (default): C-a is the local prefix. C-a C-a forwards C-a to the
#                     inner tmux, so you drive the server with a double tap.
#   REMOTE:           C-a passes straight through to the inner tmux, so a
#                     single tap drives the server. The local tmux moves its
#                     prefix to C-b (the tmux default) while remote is active.
set -euo pipefail

mode="$(tmux show -gv @nested 2>/dev/null || true)"

if [[ -n "$mode" ]]; then
  # -> LOCAL
  tmux set -gu @nested
  tmux unbind -n C-a
  tmux set -g prefix C-a
  tmux bind C-a send-prefix
  tmux display-message "nested: LOCAL (C-a C-a reaches server)"
else
  # -> REMOTE
  tmux set -g @nested on
  tmux unbind C-a
  tmux set -g prefix C-b
  tmux bind -n C-a send-keys C-a
  tmux display-message "nested: REMOTE (C-a reaches server, local prefix C-b)"
fi
