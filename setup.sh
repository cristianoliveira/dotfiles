echo "Add all symbolic links..."
mv ~/.tmux.conf  ~/old-tmux.conf
mv ~/.vimrc ~/old-vimrc
mv ~/.zshrc ~/old-zshrc
mv ~/.vim ~/old-vim
mv ~/.gitignore ~/old-gitignore
mv ~/.ctags ~/old-ctags

ln -s ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/vim/vimrc ~/.vimrc
ln -s ~/.dotfiles/zsh/zshrc ~/.zshrc
ln -s ~/.dotfiles/vim ~/.vim
ln -s ~/.dotfiles/git/gitconfig ~/.gitconfig
ln -s ~/.dotfiles/git/gitignore ~/.gitignore
ln -s ~/.dotfiles/ctags ~/.ctags

echo "Istalling tmux-setup helper"
ln -s ~/tmux/tmux-setup /usr/local/bin/tmux-setup

echo "Installing zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" &

git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

chsh -s /bin/zsh

echo "Dotfiles has been executed."
echo "Installed: zsh, vim and tmux"
