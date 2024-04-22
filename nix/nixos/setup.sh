#!/usr/bin/env bash

set -e

echo "Creating .config/nix folder"

export BACKUPNAME="nixbkp-$(date +%s)"
echo "Backup found in /tmp/$BACKUPNAME"

if [ -d "$HOME"/.config ]; then
  echo "Backing up your current configs: .config"
  mv $HOME/.config /tmp/$BACKUPNAME
fi;

mkdir -p $HOME/.config/nix

if ! command -v nix-env &> /dev/null; then
  echo "Nix is not installed. Make sure to install it."
  exit 1
fi

if [ ! -f "$HOME/.config/nix/nix.conf" ]; then
  echo "Configuring Nix..."
  mkdir -p "$HOME/.config/nix"
  ln -s "$HOME/.dotfiles/nix/nix.conf" "$HOME/.config/nix/nix.conf"
fi

# This is probably not necessary
# TODO test without this
echo "Cleaning up /etc/nixos/*"
sudo mv /etc/nixos /tmp/"$BACKUPNAME"
sudo ln -s $HOME/.dotfiles/nix/nixos /etc/nixos
sudo nixos-generate-config

# link all configs in ~/.config

# So environment is updated before running rebuild.sh
sh -c "$HOME/.dotfiles/nix/rebuild.sh"

echo "Setting up nixos applications"
$HOME/.dotfiles/nix/nixos/sway/setup.sh
$HOME/.dotfiles/nix/nixos/i3status/setup.sh
$HOME/.dotfiles/nix/nixos/fonts/setup.sh

echo "Setting up shared applications"
$HOME/.dotfiles/nvim/setup.sh
$HOME/.dotfiles/tmux/setup.sh
$HOME/.dotfiles/zsh/setup.sh
$HOME/.dotfiles/nix/shared/alacritty/setup.sh
$HOME/.dotfiles/git/setup.sh

echo "System is ready to be built with ~/.dotfiles/nix/rebuild.sh"
