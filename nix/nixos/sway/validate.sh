#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

export SWAYSOCK=$(ls /run/user/1000/sway-ipc.* | head -n 1)

sway --validate

swaymsg reload

echo "Sway reload"
