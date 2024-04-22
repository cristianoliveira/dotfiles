#!/usr/bin/env bash

set -e

echo "Setting up tmux"

if [ -f "$HOME"/.tmux.conf ]; then
  echo "Backing up your current configs: tmux"
  mv "$HOME"/.tmux.conf /tmp/"$BACKUPNAME"
fi

ln -s "$HOME"/.dotfiles/tmux/tmux.conf "$HOME"/.tmux.conf

# Create work and other directories
echo "Creating project directories: work/ and other/"
mkdir -p "$HOME"/work
mkdir -p "$HOME"/other
