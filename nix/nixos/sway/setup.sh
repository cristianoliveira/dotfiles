#!/bin/sh

echo "Linking config to $HOME/.config/sway"
mv -f $HOME/.config/sway $HOME/.config/sway.bak
ln -s $HOME/.dotfiles/nix/nixos/sway $HOME/.config/
