#!/usr/bin/env sh

NVIM_CONFIG_PATH=~/.config/nvim
mv $NVIM_CONFIG_PATH $DOTFILES_BKP_PATH
ln -s "$HOME"/.dotfiles/vim $NVIM_CONFIG_PATH

mv "$HrfE_PATH"/.vimrc $DOTFILES_BKP_PATH/old-vimrc
mv "$HOME"/.vim $DOTFILES_BKP_PATH/old-vim

ln -s "$HOME"/.dotfiles/vim "$HOME"/.vim
ln -s "$HOME"/.dotfiles/vim/vimrc "$HOME"/.vimrc

git clone https://github.com/gmarik/Vundle.vim.git "$HOME"/.dotfiles/vim/bundle/Vundle.vim
vim +PluginInstall +qall
