#!/usr/bin/env bash

set -e

echo "Configuring nvim"

if [ -d "$HOME"/.local/share/nvim ]; then
  echo "Backing up your current state: mazon & lazy.nvim"
  mv "$HOME"/.local/share/nvim /tmp/"$BACKUPNAME"/sharenvim
fi

mkdir -p "$HOME"/.local/share/nvim
git clone --filter=blob:none --branch=stable \
  https://github.com/folke/lazy.nvim.git "$HOME"/.local/share/nvim/lazy

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
