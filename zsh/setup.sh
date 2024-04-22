#!/usr/bin/env bash

set -e

echo "Setting up zsh"

if [ -f "$HOME"/.zshrc ]; then
  echo "Backing up your current configs: zshrc"
  mv "$HOME"/.zshrc /tmp/"$BACKUPNAME"
fi

ln -s "$HOME"/.dotfiles/zsh/zshrc "$HOME"/.zshrc
