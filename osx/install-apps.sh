#!/bin/bash

command -v brew > /dev/null || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"

brew tap Homebrew/bundle

echo; echo ">> Setting the right grants for apps"
sudo chown -R `whoami`:admin /usr/local/bin
sudo chown -R `whoami`:admin /usr/local/share

brew link gdbm xz pcre

echo; echo ">> Installing Apps"
brew bundle --verbose --file=$HOME/.dotfiles/osx/Brewfile
