echo; echo "Installing RVM"

curl -sSL https://get.rvm.io | bash

export PATH="$PATH:$HOME/.rvm/bin"

rvm install ruby --latest

rvm get stable --auto-dotfiles
