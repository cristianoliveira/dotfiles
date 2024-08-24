#!/usr/bin/env bash

set -e

echo "Configuring nvim"

if [ -d "$HOME"/.local/share/nvim ]; then
  echo "Backing up your current state: mazon & lazy.nvim"
  mv "$HOME/.local/share/nvim" "/tmp/$BACKUPNAME/sharenvim"
  mv "$HOME/.local/state/nvim" "/tmp/$BACKUPNAME/statenvim"
fi

echo "Linking config to $HOME/.config/nvim"
if [ -f "$HOME"/.config/nvim ]; then
  echo "Backing up your current configs: nvim"
  mv "$HOME"/.config/nvim /tmp/"$BACKUPNAME"
fi
ln -s "$HOME"/.dotfiles/nvim "$HOME"/.config/nvim

# before nix
# pip install --user --upgrade pynvim

echo "Setting up ctags"
if [ -f "$HOME"/.ctags ]; then
  echo "Backing up your current configs: ctags"
  mv "$HOME"/.ctags /tmp/"$BACKUPNAME"
fi
ln -s "$HOME"/.dotfiles/ctags "$HOME"/.ctags
