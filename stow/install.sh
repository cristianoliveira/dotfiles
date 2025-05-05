#!/usr/bin/env bash

set -e

# list all packages in stow directory
packages=$(ls -d ./stow/*)
echo "Installing shared packages"
for package in $packages; do
    pkg=$(basename "$package")
    if [ "install.sh" = "$pkg" ] || \
        [ "Linux" = "$pkg" ] || \
        [ "Darwin" = "$pkg" ]; then
        continue
    fi

    echo "Create links for $pkg"
    stow -d stow -t $HOME $pkg
done

os="$(uname)"
packages="$(ls -d ./stow/$os/*)"
echo "Installing packages for $os"
for package in $packages; do
    pkg=$(basename "$package")
    if [ "install.sh" = "$pkg" ]; then
        continue
    fi

    echo "Create links for $pkg"
    stow -d "stow/$os" -t $HOME $pkg
done
