#!/bin/sh

# This is probably not necessary
# TODO test without this
# sudo ln -s $HOME/.dotfiles/nix/nixos/configuration.nix /etc/nixos/
# sudo ln -s $HOME/.dotfiles/nix/nixos/hardware-configuration.nix /etc/nixos/

# link all configs in ~/.config
mkdir -p $HOME/.config
$HOME/.dotfiles/nix/nixos/sway/setup.sh
$HOME/.dotfiles/nix/nixos/i3status/setup.sh
$HOME/.dotfiles/nix/nixos/fonts/setup.sh

$HOME/.dotfiles/resources/alacritty/setup.sh

if ! command -v nix-env &> /dev/null; then
  echo "Nix is not installed. Make sure to install it."
  exit 1
fi

if [ ! -f "$HOME/.config/nix/nix.conf" ]; then
  echo "Configuring Nix..."
  mkdir -p "$HOME/.config/nix"
  ln -s "$HOME/.dotfiles/nix/nix.conf" "$HOME/.config/nix/nix.conf"
fi

# So environment is updated before running rebuild.sh
sh -c "$HOME/.dotfiles/nix/rebuild.sh"

echo "System is ready to be built with ~/.dotfiles/nix/rebuild.sh"
