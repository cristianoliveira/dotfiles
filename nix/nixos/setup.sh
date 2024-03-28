#!/bin/sh

# This is probably not necessary
# TODO test without this
sudo ln -s $HOME/.dotfiles/nix/nixos/configuration.nix /etc/nixos/
sudo ln -s $HOME/.dotfiles/nix/nixos/hardware-configuration.nix /etc/nixos/

# link all configs in ~/.config
mkdir -p $HOME/.config
$HOME/.dotfiles/nix/nixos/sway/setup.sh
$HOME/.dotfiles/nix/nixos/i3status/setup.sh
$HOME/.dotfiles/nix/nixos/fonts/setup.sh

if ! command -v nix-env &> /dev/null; then
  echo "Nix is not installed. Make sure to install it."
  exit 1
fi

echo "System is ready to be built with ~/.dotfiles/nix/rebuild.sh"
