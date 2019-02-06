cd linux

echo "\n\n\n\n\n----------------------Running scripts-------------------\n\n\n\n\n"
cd $HOME/.dotfiles/scripts-install
sh install-all.sh
cd $HOME

echo "Setup linux machine"
sh ./setup.sh
