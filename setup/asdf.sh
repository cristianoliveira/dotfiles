if [ -d "$HOME/.asdf" ]; then
  echo "asdf already installed"
  exit 0
fi

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

. $HOME/.dotfiles/zsh/settings/asdf.zsh

asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add python
