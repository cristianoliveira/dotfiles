set -e  # fail on error
set -u # do not allow unset variables

echo "Installing apps for osx"
sudo chown -R $(whoami) /usr/local/lib/pkgconfig

printf "\n\n\n\n\n"
echo "-------------Installing deps-------------------"
printf "\n\n\n\n\n"
$HOME/.dotfiles/nix/osx/setup.sh
