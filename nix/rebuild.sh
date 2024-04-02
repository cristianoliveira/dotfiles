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
  sudo nixos-rebuild switch --flake $HOME/.dotfiles/nix#nixos
fi

## Ask if wants to commit, amend or discard changes
echo "Do you want to commit the changes? [y/n]"
read -r answer
if [ "$answer" = "y" ]; then
  echo "New commit? Otherwise amend to the last. [y/n]"
  read -r answer
  if [ "$answer" = "y" ]; then
    git commit
  else
    git commit --amend
  fi
fi
