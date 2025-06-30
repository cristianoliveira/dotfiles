#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

export SWAYSOCK=$(sway --get-socketpath)

sway --validate

swaymsg reload

echo "Sway reload"
