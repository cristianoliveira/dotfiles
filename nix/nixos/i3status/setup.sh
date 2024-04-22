#!/bin/sh

echo "Linking config to $HOME/.config/i3status"
[ -f "$HOME"/.config/i3status ] && mv -f  "$HOME"/.config/i3status "$HOME"/.config/i3status.bkp
ln -s $HOME/.dotfiles/nix/nixos/i3status $HOME/.config/
