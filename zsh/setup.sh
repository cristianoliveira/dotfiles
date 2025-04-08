#!/usr/bin/env bash

set -e

echo "Setting up zsh"

if [ -f "$HOME"/.zshrc ]; then
  echo "Backing up your current configs: zshrc"
  mv "$HOME"/.zshrc /tmp/"$BACKUPNAME"
fi

ln -sf "$HOME"/.dotfiles/zsh/zshrc "$HOME"/.zshrc

chsh -s "$(which zsh)"

echo "Create local bin folder if it does not exist"
mkdir -p "$HOME"/.local/bin
