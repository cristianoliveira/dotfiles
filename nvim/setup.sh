#!/usr/bin/env sh

NVIM_CONFIG_PATH=~/.config/nvim
mv $NVIM_CONFIG_PATH $DOTFILES_BKP_PATH
ln -s "$HOME"/.dotfiles/nvim $NVIM_CONFIG_PATH

python3 -m pip install --user --upgrade pynvim
