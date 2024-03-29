#!/bin/sh

# Check https://github.com/nix-community/nix-direnv

echo "Configuring direnv to use nix"
echo "use nix" > $HOME/.envrc
direnv allow
