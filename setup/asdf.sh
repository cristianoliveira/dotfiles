#!/bin/sh

if command -v asdf &> /dev/null; then
  echo "asdf already installed"
  exit 0

else
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

  . $HOME/.dotfiles/zsh/settings/asdf.zsh
fi

asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add python
