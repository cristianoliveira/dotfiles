#!/usr/bin/env bash

echo "Linking mappings configs for dual function keys"

if [ -d /etc/mappings ]; then
  echo "Cleaning up /etc/mappings/*"
  sudo mv /etc/mappings /tmp/mappings
fi

sudo ln -sf $HOME/.dotfiles/nix/nixos/mappings /etc/
