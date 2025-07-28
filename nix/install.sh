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

## First run setup
bash "$HOME/.dotfiles/nix/$OSTARGET/install.sh"

# Make sure the nix profile is in the PATH before running 
# next scripts
export PATH="/run/current-system/sw/bin:$PATH"

bash "$HOME/.dotfiles/stow/install.sh"
