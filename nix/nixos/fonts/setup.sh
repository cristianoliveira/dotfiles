#!/usr/bin/env bash

set -e

echo "Setting up Monaco font"
mkdir -p "$HOME"/.local/share/fonts
mv -f "$HOME"/.local/share/fonts /tmp/"$BACKUPNAME"
ln -s "$HOME"/.dotfiles/nix/nixos/fonts "$HOME"/.local/share/fonts
fc-cache -f -v
