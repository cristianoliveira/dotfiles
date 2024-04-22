#!/usr/bin/env bash

set -e

echo "Configuring nvim"

if [ -d "$HOME"/.config/nvim ]; then
  echo "Backing up your current configs: nvim"
  mv "$HOME"/.config/nvim /tmp/"$BACKUPNAME"
fi

ln -s "$HOME"/.dotfiles/nvim "$HOME"/.config/nvim

# before nix
# pip install --user --upgrade pynvim
