#!/usr/bin/env bash

set -e

echo "Linking config to $HOME/.config/i3status"

if [ -f "$HOME"/.config/i3status ]; then
  echo "Backing up your current configs: i3status"
  mv -f  "$HOME"/.config/i3status /tmp/"$BACKUPNAME"
fi

ln -sf $HOME/.dotfiles/nix/nixos/i3status $HOME/.config/i3status
