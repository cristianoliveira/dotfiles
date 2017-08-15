echo "Installing apps for osx"
sh $HOME/.dotfiles/osx/install-apps.sh

"Configuring machine as 'squall'"
sh $HOME/.dotfiles/osx/configure-osx.sh squall

sh $HOME/.dotfiles/setup.sh
