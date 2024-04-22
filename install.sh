set -e # fail on error
set -u # do not allow unset variables

OS=f$1
if [ "$OS" = "" ]
then
  echo "Missing OS "
  echo "Options: osx, linux"
  exit
fi

echo "Clonning dotfiles"
nix-shell \
  -p git vim \
  --command "git clone https://github.com/cristianoliveira/dotfiles.git ~/.dotfiles"

cd ~/.dotfiles

## IF OS is osx
if [ "$OS" = "osx" ]; then
  echo "Installing for OSX"
  ./nix/osx/setup.sh
fi

if [ "$OS" = "linux" ]; then
  echo "Installing for OSX"
  ./nix/nixos/setup.sh
else
  echo "OS not supported: $OS"
  echo "Options: osx, linux"
  exit
fi
