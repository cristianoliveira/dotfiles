#!/bin/sh

# Since alacritty is installed as a binary, we need to create a symlink to the
# ~/Applications directory so that it can be found by alfred.

# check if alacritty is installed
if ! command -v alacritty &> /dev/null; then
  echo "Alacritty is not installed. Please run 'nix/rebuild.sh'"
  exit 1
fi

mkdir ~/Applications/Alacritty.app
ln -s "$(which alacritty)" ~/Applications/Alacritty.app

# See also ~/.dotfiles/resources/alacritty/ for the configuration file.
