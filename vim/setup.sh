mv "$HOME_PATH"/.vimrc $DOTFILES_BKP_PATH/old-vimrc
mv "$HOME_PATH"/.vim $DOTFILES_BKP_PATH/old-vim

ln -s "$HOME_PATH"/.dotfiles/vim "$HOME_PATH"/.vim
ln -s "$HOME_PATH"/.dotfiles/vim/vimrc "$HOME_PATH"/.vimrc

git clone https://github.com/gmarik/Vundle.vim.git "$HOME_PATH"/.dotfiles/vim/bundle/Vundle.vim
vim +PluginInstall +qall
