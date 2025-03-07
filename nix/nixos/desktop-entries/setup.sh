#!/bin/sh

set -e

# Create the directory for the desktop entries
entries="$HOME/.dotfiles/nix/nixos/desktop-entries/"
for file in $(find $entries -type f -name "*.desktop"); do
  echo "Creating directory: $file"

  ln -sf $file $HOME/.local/share/applications/
done
