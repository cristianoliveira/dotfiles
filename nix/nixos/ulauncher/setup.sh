#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Linking config to $HOME/.config/ulauncher"

mkdir -p $HOME/.config/ulauncher

ln -sTf $HOME/.dotfiles/nix/nixos/ulauncher/settings.json $HOME/.config/ulauncher/settings.json
ln -sTf $HOME/.dotfiles/nix/nixos/ulauncher/extensions.json $HOME/.config/ulauncher/extensions.json
ln -sTf $HOME/.dotfiles/nix/nixos/ulauncher/shortcuts.json $HOME/.config/ulauncher/shortcuts.json
