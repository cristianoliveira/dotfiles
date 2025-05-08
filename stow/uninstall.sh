#!/usr/bin/env bash

set -e

. $HOME/.dotfiles/stow/common.sh

PKG_NAME=${1:-""}

if [ "$PKG_NAME" != "" ]; then
    echo "Uninstalling $PKG_NAME"
fi

# list all packages in stow directory
packages=$(ls -d ./stow/*)
echo "Removing shared packages"
for package in $packages; do
    # Check if the package is a directory
    if [ ! -d "$package" ]; then
        continue
    fi

    pkg=$(basename "$package")
    if [ "install.sh" = "$pkg" ] || \
        [ "Linux" = "$pkg" ] || \
        [ "Darwin" = "$pkg" ]; then
        continue
    fi

    if [ "$PKG_NAME" != "" ] && [ "$PKG_NAME" != "$pkg" ]; then
        continue
    fi

    echo "<< Removing links for $pkg"
    package_before_install "$package"
    stow -d stow -t $HOME -D $pkg
    package_after_install "$package"
done

os="$(uname)"
packages="$(ls -d ./stow/$os/*)"
echo "Installing packages for $os"
for package in $packages; do
    # Check if the package is a directory
    if [ ! -d "$package" ]; then
        continue
    fi

    pkg=$(basename "$package")
    if [ "install.sh" = "$pkg" ]; then
        continue
    fi

    if [ "$PKG_NAME" != "" ] && [ "$PKG_NAME" != "$pkg" ]; then
        continue
    fi

    echo "<< Removing links for $pkg"
    package_before_install "$package"
    stow -d "stow/$os" -t $HOME -D $pkg
    package_after_install "$package"
done
