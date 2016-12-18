ln -s ~/.tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/.vimrc ~/.vimrc
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/.dotfiles/vim ~/.vim
ln -s ~/.dotfiles/git/gitconfig ~/.gitconfig

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

curl https://cdn.rawgit.com/zsh-users/antigen/v1.3.1/bin/antigen.zsh > antigen.zsh
source antigen.zsh

git clone git@github.com:clvv/fasd.git /tmp/fasd
cd /tmp/fasd && sudo make install

git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall
