#!/bin/sh
#
set -e

sudo nixos-rebuild switch --flake $HOME/.dotfiles/nix#nixos

git add nix/ -p
git commit
