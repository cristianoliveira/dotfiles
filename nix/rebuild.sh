#!/bin/sh
#
set -e

git diff ~/.dotfiles/nix
sudo nixos-rebuild switch

git add nix/ -p
git commit
