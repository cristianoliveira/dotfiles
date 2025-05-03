#!/bin/sh
#
# This look for all **/setup.sh files and run them one by one
#
# Usage: ./setup.sh
#

sysname=$(uname)

if [ "$sysname" == "Darwin" ]; then
    OSTARGET="osx"
elif [ "$sysname" == "Linux" ]; then
    OSTARGET="nixos"
else
    echo "Unknown OSTARGET: $sysname"
    exit 1
fi

## First install os specific tools
bash "$HOME/.dotfiles/nix/$OSTARGET/install.sh"

for setup in $(find $HOME/.dotfiles/nix/$OSTARGET -name "setup.sh"); do
    echo "NixOs: Running $setup"
    bash $setup
done

for setup in $(find $HOME/.dotfiles/nix/shared -name "setup.sh"); do
    echo "Shared: running $setup"
    bash $setup
done

# check for folders in the root level but only one level deep
for setup in $(find $HOME/.dotfiles/ -maxdepth 2 -name "setup.sh"); do
    echo "Running $setup"
    bash $setup
done
