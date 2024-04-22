#!/usr/bin/env bash

set -e

echo "Linking config to $HOME/.config/ulauncher"

if [ -d "$HOME"/.config/ulauncher ]; then
  echo "Backing up your current configs: ulauncher"
  mv "$HOME"/.config/ulauncher /tmp/"$BACKUPNAME"
fi

mkdir -p $HOME/.config/ulauncher

ln -s $HOME/.dotfiles/nix/nixos/ulauncher/settings.json $HOME/.config/ulauncher/settings.json
ln -s $HOME/.dotfiles/nix/nixos/ulauncher/extensions.json $HOME/.config/ulauncher/extensions.json
ln -s $HOME/.dotfiles/nix/nixos/ulauncher/shortcuts.json $HOME/.config/ulauncher/shortcuts.json
