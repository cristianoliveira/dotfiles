#!/usr/bin/env bash

set -e

## Reindex ~/Applitions

# echo ">>> Copying ~/Applications"
cp -rf $HOME/.dotfiles/nix/osx/Applications/* ~/Applications

echo ">>> Reindexing ~/Applications"
mdimport ~/Applications

# sudo mdutil -E /
