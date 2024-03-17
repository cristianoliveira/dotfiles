#!/bin/sh
#
# TODO run this script upon nix setup

mkdir -p $HOME/.local/share/fonts
cp -s $HOME/.dotfiles/nix/fonts/* $HOME/.local/share/fonts
fc-cache -f -v
