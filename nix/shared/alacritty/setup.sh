#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Setting up alacritty"

# Backup only when folder exist
[ -d "$HOME"/.config/alacritty ] && mv -f "$HOME"/.config/alacritty "$HOME"/.config/alacritty.bak
ln -sf "$HOME"/.dotfiles/nix/shared/alacritty "$HOME"/.config/alacritty
