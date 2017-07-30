echo "Add all symbolic links..."
cp ~/.tmux.conf  ~/old-tmux.conf
cp ~/.vimrc ~/old-vimrc
cp ~/.zshrc ~/old-zshrc
cp ~/.vim ~/old-vim
cp ~/.gitignore ~/old-gitignore
cp ~/.ctags ~/old-ctags

ln -s ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/vim/vimrc ~/.vimrc
ln -s ~/.dotfiles/zsh/zshrc ~/.zshrc
ln -s ~/.dotfiles/vim ~/.vim
ln -s ~/.dotfiles/git/gitconfig ~/.gitconfig
ln -s ~/.dotfiles/git/gitignore ~/.gitignore
ln -s ~/.dotfiles/ctags ~/.ctags

echo "Installing zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" &

git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

echo "Installing rbenv"
git clone https://github.com/rbenv/rbenv.git rbenv
ln -s ~/.dotfiles/rbenv ~/.rbenv
eval "$(~/.rbenv/bin/rbenv init -)"

echo "dotfiles executed."
echo "Installed: zsh, vim and tmux"
echo "Configured."
