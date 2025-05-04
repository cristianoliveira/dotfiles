#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Setting up yabai - tiling window manager"

# Link yabai configuration
# If the ~/.yabairc file exists, back it up
if [ -f "$HOME/.yabairc" ]; then
  echo "Backing up existing yabai configuration."
  # Backup the existing yabai configuration
  mv -f "$HOME/.yabairc" "$HOME/.yabairc.bkp"
fi
# If the ~/.skhdrc file exists, back it up
if [ -f "$HOME/.skhdrc" ]; then
  echo "Backing up existing skhd configuration."
  # Backup the existing skhd configuration
  mv -f "$HOME/.skhdrc" "$HOME/.skhdrc.bkp"
fi

ln -sf "$HOME/.dotfiles/nix/osx/yabai/yabairc" "$HOME/.yabairc"
ln -sf "$HOME/.dotfiles/nix/osx/yabai/skhdrc" "$HOME/.skhdrc"

echo "yabai setup complete"
