#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together


## Check if nix is installed and available
if ! command -v nix &> /dev/null; then
  read -p "Do you want to install Nix? (y/n) " ANSWER
  if [[ $ANSWER =~ ^[Yy]$ ]]; then
    echo "Installing Nix"
    sh <(curl -L https://nixos.org/nix/install)
  else
    echo "Skipping Nix installation"
  fi
fi

## Check if homebrew is installed
if ! command -v brew &> /dev/null; then
  read -p "Do you want to install Homebrew? (y/n) " ANSWER
  if [[ $ANSWER =~ ^[Yy]$ ]]; then
    echo "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Skipping Homebrew installation"
  fi
fi

## Check if darwin-rebuild is installed
if ! command -v darwin-rebuild &> /dev/null; then
  read -p "Do you want to install darwin-rebuild? (y/n) " ANSWER
  if [[ $ANSWER =~ ^[Yy]$ ]]; then
    echo "Installing darwin-rebuild"
    /nix/var/nix/profiles/default/bin/nix profile install \
      --extra-experimental-features nix-command \
      --extra-experimental-features flakes \
      nix-darwin/nix-darwin-24.11#darwin-rebuild
  else
    echo "Skipping darwin-rebuild installation"
  fi
fi

echo "Linking Nix Darwin configuration"
mkdir -p "$HOME/.nixpkgs"
rm -f "$HOME/.nixpkgs/darwin-configuration.nix"
ln -sf "$HOME/.dotfiles/nix/osx/configuration.nix" "$HOME/.nixpkgs/darwin-configuration.nix"


if [ ! -f "$HOME/.config/nix/nix.conf" ]; then
  echo "Configuring Nix (~/.dotfiles/nix/nix.conf)"
  mkdir -p "$HOME/.config/nix"
  ln -sf "$HOME/.dotfiles/nix/nix.conf" "$HOME/.config/nix/nix.conf"
fi

echo "System is ready to be built with ~/.dotfiles/nix/rebuild.sh"
echo "Running darwin-rebuild switch"

NIXOS_CONFIG=$HOME/.dotfiles/nix
/nix/var/nix/profiles/default/bin/nix run \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  nix-darwin/nix-darwin-24.11#darwin-rebuild switch \
  --flake $HOME/.dotfiles/nix#darwin

echo "Setup complete"
