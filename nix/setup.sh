#!/usr/bin/env bash
#
set -e

system=$(uname)

echo "System: $system"
echo "Setting up applications `.config` folder"

if [ ! -d "$HOME/.config" ]; then
  echo "Creating ~/.config folder"
  mkdir -p "$HOME/.config"
fi

echo "Linking alacritty configuration"
if [ "$(uname)" = "Darwin" ]; then
  # OSX (darwin)
  echo "Rebuilding Darwin configuration..."
  # ./osx/setup.sh
else
  echo "Rebuilding NixOS configuration..."
  # ./nixos/setup.sh
fi
