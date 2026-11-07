#!/usr/bin/env bash
set -euo pipefail

# Keep Herdr's mutable state outside the Stow package.
mkdir -p "$HOME/.config/herdr-app/mods"
