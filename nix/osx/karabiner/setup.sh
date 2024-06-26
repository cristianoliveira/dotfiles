#!/bin/sh

echo "Setting up Karabiner configurations."

mkdir -p "$HOME"/.config
mv -f "$HOME"/.config/karabiner "$HOME"/.config/karabiner.bkp
ln -s "$HOME"/.dotfiles/resources/karabiner "$HOME"/.config/karabiner
