#!/bin/sh
# Brouter executable targets cannot pass profile arguments.
set -eu

profile="Profile 2"
if [ ! -d "$HOME/Library/Application Support/Google/Chrome Canary/$profile" ]; then
  printf 'Canary profile does not exist: %s\n' "$profile" >&2
  exit 1
fi

exec "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" \
  "--profile-directory=$profile" "$@"
