#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

echo "linking finicky configuration file"
mv "$HOME/.finicky.js" "$HOME/.finicky.js.bak"
ln -sTf "$HOME/.dotfiles/nix/osx/finicky/finicky.js" "$HOME/.finicky.js"
