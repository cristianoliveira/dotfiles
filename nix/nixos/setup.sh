#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Creating .config/nix folder"

export BACKUPNAME="nixbkp-$(date +%s)"
echo "Backup found in /tmp/$BACKUPNAME"

if [ -d "$HOME"/.config ]; then
  echo "Backing up your current configs: .config"
  # Move and ignore if it already exists
  mv -f "$HOME"/.config /tmp/"$BACKUPNAME"
fi;

mkdir -p $HOME/.config/nix

if ! command -v nix-env &> /dev/null; then
  echo "Nix is not installed. Make sure to install it."
  exit 1
fi

# This is probably not necessary
# TODO test without this
if [ -d /etc/nixos ]; then
  echo "Cleaning up /etc/nixos/*"
  sudo mv /etc/nixos /tmp/"$BACKUPNAME"
  sudo ln -sTf $HOME/.dotfiles/nix/nixos /etc/nixos
  sudo nixos-generate-config
fi

# link all configs in ~/.config

echo "Setting up nixos applications"
$HOME/.dotfiles/nix/nixos/sway/setup.sh
$HOME/.dotfiles/nix/nixos/i3status/setup.sh
$HOME/.dotfiles/nix/nixos/fonts/setup.sh
$HOME/.dotfiles/nix/nixos/ulauncher/setup.sh
$HOME/.dotfiles/nix/nixos/rclone/setup.sh
$HOME/.dotfiles/nix/nixos/services/setup.sh

echo "Setting up shared applications"
"$HOME"/.dotfiles/nix/shared/setup.sh

# So environment is updated before running rebuild.sh
echo "Installing dependencies and rebuilding system..."
sh -c "SKIP_COMMIT=1 $HOME/.dotfiles/nix/rebuild.sh"

echo "System is ready to be built with ~/.dotfiles/nix/rebuild.sh"
