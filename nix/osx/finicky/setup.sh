#!/bin/sh

echo "linking finicky configuration file"
mv "$HOME/.finicky.js" "$HOME/.finicky.js.bak"
ln -s "$HOME/.dotfiles/nix/osx/finicky/finicky.js" "$HOME/.finicky.js"
