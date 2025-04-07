#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Running shared setup"

echo "Setting up shared applications"
$HOME/.dotfiles/git/setup.sh
$HOME/.dotfiles/nvim/setup.sh
$HOME/.dotfiles/tmux/setup.sh
$HOME/.dotfiles/zsh/setup.sh
$HOME/.dotfiles/nix/shared/alacritty/setup.sh
