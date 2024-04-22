#!/bin/sh

echo "Linking config to $HOME/.config/sway"
if [ -f "$HOME"/.config/sway ]; then
  echo "Backing up your current configs: sway"
  mv -f $HOME/.config/sway /tmp/"$BACKUPNAME"
fi

ln -s $HOME/.dotfiles/nix/nixos/sway $HOME/.config/
