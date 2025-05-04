#!/usr/bin/env bash

set -e

# list all packages in stow directory
packages=$(ls -d stow/* | sed 's#stow\/##')
echo "Available packages: $packages"
for package in $packages; do
    # only if is a directory
    if [ ! -d "$package" ]; then
        continue
    fi

    echo "Installing $package"
    stow -d stow -t $HOME $package
done
