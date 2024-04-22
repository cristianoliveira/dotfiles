#!/usr/bin/env bash

set -e

echo "Setting up Monaco font"
## Makes a backup
if [ -d "$HOME"/.local/share/fonts ]; then
  echo "Backing up your current fonts"
  mv -f "$HOME"/.local/share/fonts /tmp/"$BACKUPNAME"
fi

mkdir -p "$HOME"/.local/share

ln -s "$HOME"/.dotfiles/nix/nixos/fonts "$HOME"/.local/share/fonts

fc-cache -f -v
