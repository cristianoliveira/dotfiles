#!/bin/bash

command -v brew > /dev/null || (echo; echo ">> Homebrew" && ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)")

brew tap Homebrew/bundle

echo; echo ">> Setting the right grants for apps"
sudo chown -R `whoami`:admin /usr/local/bin
sudo chown -R `whoami`:admin /usr/local/share

brew link gdbm xz pcre

echo; echo ">> Installing Apps"
brew bundle --verbose --file=$HOME/.dotfiles/osx/Brewfile

echo; echo ">> Installing Basher"
git clone https://github.com/basherpm/basher.git ~/.basher
