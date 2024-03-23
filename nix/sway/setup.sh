#!/bin/sh

echo "Linking config to $HOME/.config/sway"
ln -s $HOME/.dotfiles/nix/sway $HOME/.config/
