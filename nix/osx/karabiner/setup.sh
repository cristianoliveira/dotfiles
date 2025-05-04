#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Setting up Karabiner configurations."

mkdir -p "$HOME"/.config
if [ -d "$HOME"/.config/karabiner ]; then
  echo "Backing up existing Karabiner configuration."
  # Backup the existing Karabiner configuration
  mv -f "$HOME"/.config/karabiner "$HOME"/.config/karabiner.bkp
fi

ln -sf "$HOME"/.dotfiles/nix/osx/karabiner "$HOME"/.config/karabiner
