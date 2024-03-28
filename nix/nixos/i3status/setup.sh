#!/bin/sh

echo "Linking config to $HOME/.config/i3status"
mv -f $HOME/.config/i3status/config $HOME/.config/i3status/config.bak
ln -s $HOME/.dotfiles/nix/nixos/i3status $HOME/.config/
