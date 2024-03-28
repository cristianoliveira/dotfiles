#!/bin/sh

echo "Linking config to $HOME/.config/i3status"
mv $HOME/.config/i3status/config $HOME/.config/i3status/config.bak
ln -s $HOME/.dotfiles/nix/nixos/i4status $HOME/.config/
