#!/usr/bin/env bash

set -e

# list all packages in stow directory
packages=$(ls -d stow/* | sed 's#stow\/##')
echo "Installing packages"
for package in $packages; do
    # only if is a directory
    if [ "install.sh" = "$package" ]; then
        continue
    fi

    echo "Installing $package"
    stow -d stow -t $HOME $package
done
