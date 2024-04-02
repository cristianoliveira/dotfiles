#!/bin/sh

echo "Linking config to $HOME/.config/ulauncher"
mkdir -p $HOME/.config/ulauncher

rm -rf $HOME/.config/ulauncher/*.json

ln -s $HOME/.dotfiles/nix/nixos/ulauncher/settings.json $HOME/.config/ulauncher/settings.json
ln -s $HOME/.dotfiles/nix/nixos/ulauncher/extensions.json $HOME/.config/ulauncher/extensions.json
ln -s $HOME/.dotfiles/nix/nixos/ulauncher/shortcuts.json $HOME/.config/ulauncher/shortcuts.json
