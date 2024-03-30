#!/bin/sh

echo "Setting up alacritty"

mv -f "$HOME"/.config/alacritty "$HOME"/.config/alacritty.bak
mkdir -p "$HOME"/.config/alacritty
ln -sf "$HOME"/.dotfiles/resources/alacritty "$HOME"/.config/alacritty
