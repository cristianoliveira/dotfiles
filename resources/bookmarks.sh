#!/bin/sh

# zip file with a password when arg is "zip"
if [ "$1" = "zip" ]; then
  zip -e $HOME/.dotfiles/resources/bookmarks.zip $HOME/.dotfiles/resources/bookmarks
  echo "bookmarks.zip created"
  exit 0
elif [ "$1" = "unzip" ]; then
  unzip $HOME/.dotfiles/resources/bookmarks.zip
  echo "bookmarks.zip unzipped"
  exit 0
else
  echo "Usage: $0 [zip|unzip]"
  exit 1
fi
