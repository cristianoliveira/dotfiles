#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "Use SKIP_COMMIT if you want to skip git steps"

# fail if dar

# If SKIP_COMMIT is not set skip git steps
if [ -z "$SKIP_COMMIT" ]; then
  git add nix/ -p
else
  echo "Skipping commit step"
fi

if [ -z "$SKIP_COMMIT" ]; then
  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit."
    exit 0
  fi
fi

if [ "$(uname)" = "Darwin" ]; then
  # OSX (darwin)
  echo "Rebuilding Darwin configuration..."
  NIXOS_CONFIG=$HOME/.dotfiles/nix
  sudo darwin-rebuild switch --flake $HOME/.dotfiles/nix#darwin
else
  # NixOS (linux)
  NIXOS_CONFIG=$HOME/.dotfiles/nix
  echo "Rebuilding NixOS configuration..."
  sudo nixos-rebuild switch --flake $HOME/.dotfiles/nix#nixos
fi

## Ask if wants to commit, amend or discard changes
if [ -z "$SKIP_COMMIT" ]; then
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
fi
