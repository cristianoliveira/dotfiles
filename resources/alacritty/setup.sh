#!/bin/sh

echo "Setting up alacritty"

# Backup only when folder exist
[ -d "$HOME"/.config/alacritty ] && mv -f "$HOME"/.config/alacritty "$HOME"/.config/alacritty.bak
ln -sf "$HOME"/.dotfiles/resources/alacritty "$HOME"/.config/alacritty
