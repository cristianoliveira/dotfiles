#!/usr/bin/env bash

NVIM_CONFIG_PATH=~/.config/nvim
mv $NVIM_CONFIG_PATH $DOTFILES_BKP_PATH
ln -s "$HOME"/.dotfiles/nvim $NVIM_CONFIG_PATH

# before nix
# pip install --user --upgrade pynvim
