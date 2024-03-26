#!/bin/sh

# Install Nix
# sh <(curl -L https://nixos.org/nix/install)

echo "Install Nix Darwin"

read -p "Do you want to install Nix Darwin? (y/n) " ANSWER
if [[ $ANSWER =~ ^[Yy]$ ]]; then
  echo "Installing Nix Darwin"
  sh -c "nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer"
  ./result/bin/darwin-installer
else
  echo "Skipping Nix Darwin installation"
fi
