#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Linking config to $HOME/.config/sway"
if [ -f "$HOME"/.config/sway ]; then
  echo "Backing up your current configs: sway"
  mv -f $HOME/.config/sway /tmp/"$BACKUPNAME"
fi

ln -sTf $HOME/.dotfiles/nix/nixos/sway $HOME/.config/sway
