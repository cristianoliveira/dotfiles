#!/usr/bin/env bash
set -euo pipefail

# Keep Herdr's mutable state outside the Stow package.
mkdir -p "$HOME/.config/herdr-app/mods" "$HOME/.config/herdr-app/layouts" \
    "$HOME/.config/herdr-app/themes"
