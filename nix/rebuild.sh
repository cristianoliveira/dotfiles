#!/bin/sh
#
set -e

git add nix/ -p

if [ "$(uname)" = "Darwin" ]; then
  # OSX
  echo "Rebuilding Darwin configuration..."
  NIXOS_CONFIG=$HOME/.dotfiles/nix#darwin
  darwin-rebuild switch --flake $HOME/.dotfiles/nix#darwin
else
  # Linux
  NIXOS_CONFIG=$HOME/.dotfiles/nix#nixos
  echo "Rebuilding NixOS configuration..."
  sudo nixos-rebuild switch --flake $HOME/.dotfiles/nix#nixos \
    --show-trace
fi

git commit
