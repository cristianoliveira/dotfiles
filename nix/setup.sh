#!/bin/sh

# This is probably not necessary
# TODO test without this
sudo ln -s $HOME/.dotfiles/nix/nixos/configuration.nix /etc/nixos/
sudo ln -s $HOME/.dotfiles/nix/nixos/hardware-configuration.nix /etc/nixos/

sudo nixos-rebuild switch --flake $HOME/.dotfiles/nix#nixos
