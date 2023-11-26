set -e  # fail on error
set -u # do not allow unset variables

echo "----------------------Running scripts-------------------"
bash $HOME/.dotfiles/linux/install.sh

echo "Scripts path $HOME/.dotfiles/scripts-install"
bash $HOME/.dotfiles/scripts-install.sh

echo "Setup linux machine"
bash $HOME/.dotfiles/setup.sh
