#!/usr/bin/env bash

set -e

RESTOW=${RESTOW:-false}

. $HOME/.dotfiles/stow/common.sh

packageToInstall="${1:-}"

# list all packages in stow directory
packages=$(ls -d ./stow/*)
echo "Installing shared packages"
for package in $packages; do
    # Check if the package is a directory
    if [ ! -d "$package" ]; then
        continue
    fi
    # Check if install only a specific package
    if [ -z "$packageToInstall" ]; then
        # If no specific package is provided, install all packages
        echo ">> Installing all packages in $package"
    else
        # If a specific package is provided, check if it matches the current package
        pkg=$(basename "$package")
        if [ "$pkg" != "$packageToInstall" ]; then
            continue
        fi
        echo ">> Installing package $pkg"
    fi

    pkg=$(basename "$package")
    if [ "install.sh" = "$pkg" ] || \
        [ "Linux" = "$pkg" ] || \
        [ "Darwin" = "$pkg" ]; then
        continue
    fi
    package_before_install "$package"

    echo ">> Create links for $pkg"
    if [ "$RESTOW" = true ]; then
        echo ">> Restowing $pkg"
        stow -d stow -t $HOME --restow $pkg
    else
        echo ">> Stowing $pkg"
        stow -d stow -t $HOME $pkg
    fi

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

    # Check if install only a specific package
    if [ -z "$packageToInstall" ]; then
        # If no specific package is provided, install all packages
        echo ">> Installing all packages in $package"
    else
        # If a specific package is provided, check if it matches the current package
        pkg=$(basename "$package")
        if [ "$pkg" != "$packageToInstall" ]; then
            continue
        fi
        echo ">> Installing package $pkg"
    fi

    package_before_install "$package"

    echo ">> Create links for $pkg"
    if [ "$RESTOW" = true ]; then
        echo ">> Restowing $pkg"
        stow -d "stow/$os" -t $HOME --restow $pkg
    else
        echo ">> Stowing $pkg"
        stow -d "stow/$os" -t $HOME $pkg
    fi

    package_after_install "$package"
done
