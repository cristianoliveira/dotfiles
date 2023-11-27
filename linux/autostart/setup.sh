#!/bin/sh

echo "Creating onstart symlink"
if [ ! -f "/usr/local/bin/onstart" ]; then
  sudo ln -s $HOME/.dotfiles/linux/autostart/onstart.sh /usr/local/bin/onstart
fi
