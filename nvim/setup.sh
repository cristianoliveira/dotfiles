#!/usr/bin/env bash

set -e

echo "Configuring nvim"

if [ -d "$HOME"/.local/share/nvim ]; then
  echo "Backing up your current state: mazon & lazy.nvim"
  mv -f "$HOME/.local/share/nvim" "/tmp/$BACKUPNAME/sharenvim"
  mv -f "$HOME/.local/state/nvim" "/tmp/$BACKUPNAME/statenvim"
fi

echo "Linking config to $HOME/.config/nvim"
ln -sf "$HOME"/.dotfiles/nvim "$HOME"/.config/nvim

echo "Setting up ctags"
ln -sf "$HOME"/.dotfiles/ctags "$HOME"/.ctags
