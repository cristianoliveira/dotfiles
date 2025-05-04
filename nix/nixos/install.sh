#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Creating .config/nix folder"

export BACKUPNAME="nixbkp-$(date +%s)"
echo "Backup found in /tmp/$BACKUPNAME"

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
  sudo ln -sf $HOME/.dotfiles/nix/nixos /etc/nixos
  sudo nixos-generate-config
fi

# So environment is updated before running rebuild.sh
echo "Installing dependencies and rebuilding system..."
sh -c "SKIP_COMMIT=1 $HOME/.dotfiles/nix/rebuild.sh"

echo "System is ready to be built with ~/.dotfiles/nix/rebuild.sh"
