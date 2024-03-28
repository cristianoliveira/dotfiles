set -e  # fail on error
set -u # do not allow unset variables

echo "Installing apps for osx"
sudo chown -R $(whoami) /usr/local/lib/pkgconfig

printf "\n\n\n\n\n"
echo "-------------Installing deps-------------------"
printf "\n\n\n\n\n"
$HOME/.dotfiles/nix/osx/setup.sh

# FIXME Quarantine till I figure if it's needed
# echo "Configuring machine as 'squall'"
# sh $HOME/.dotfiles/osx/configure-osx.sh squall

printf "\n\n\n\n\n"
echo "-------------Setup-------------------"
printf "\n\n\n\n\n"
sh "$HOME"/.dotfiles/setup.sh

ln -s "$HOME"/.dotfiles/osx/.finicky.js "$HOME"/.finicky.js
