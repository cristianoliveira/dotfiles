#!/bin/sh
echo "Creating .config/nix folder"
mkdir -p $HOME/.config
mkdir -p $HOME/.config/nix

if ! command -v nix-env &> /dev/null; then
  echo "Nix is not installed. Make sure to install it."
  exit 1
fi

if [ ! -f "$HOME/.config/nix/nix.conf" ]; then
  echo "Configuring Nix..."
  mkdir -p "$HOME/.config/nix"
  ln -s "$HOME/.dotfiles/nix/nix.conf" "$HOME/.config/nix/nix.conf"
fi

# This is probably not necessary
# TODO test without this
echo "Cleaning up /etc/nixos/*"
sudo mv /etc/nixos /tmp/nixosbkp
sudo ln -s $HOME/.dotfiles/nix/nixos /etc/nixos
sudo nixos-generate-config

# link all configs in ~/.config
$HOME/.dotfiles/nix/nixos/sway/setup.sh
$HOME/.dotfiles/nix/nixos/i3status/setup.sh
$HOME/.dotfiles/nix/nixos/fonts/setup.sh
$HOME/.dotfiles/resources/alacritty/setup.sh

# So environment is updated before running rebuild.sh
sh -c "$HOME/.dotfiles/nix/rebuild.sh"

echo "System is ready to be built with ~/.dotfiles/nix/rebuild.sh"
