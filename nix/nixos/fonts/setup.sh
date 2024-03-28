#!/bin/sh
#
# TODO run this script upon nix setup

echo "Setting up Monaco font"
mkdir -p $HOME/.local/share/fonts
mv -f $HOME/.local/share/fonts $HOME/.local/share/fonts.bak
ln -s $HOME/.dotfiles/nix/nixos/fonts $HOME/.local/share/fonts
fc-cache -f -v
