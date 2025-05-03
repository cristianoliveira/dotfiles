#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Setting up Karabiner configurations."

mkdir -p "$HOME"/.config
mv -f "$HOME"/.config/karabiner "$HOME"/.config/karabiner.bkp
ln -sTf "$HOME"/.dotfiles/nix/osx/karabiner "$HOME"/.config/karabiner
