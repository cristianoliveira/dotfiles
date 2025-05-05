#!/usr/bin/env bash

set -e

## Package setup
# If the package folder contains an $pkg/before_install.sh file,
# it will be executed before the package is linked.
function package_before_install() {
    local pkgpath="$1"
    local setup_file="$pkgpath/before_install.sh"
    local pkg=$(basename "$pkgpath")

    if [ -f "$setup_file" ]; then
        echo "Running: $pkgpath"
        bash "$setup_file"
    fi
}

## Package after install
# If the package folder contains an $pkg/after_install.sh file
# it will be executed after the package is linked.
function package_after_install() {
    local pkgpath="$1"
    local setup_file="$pkgpath/after_install.sh"
    local pkg=$(basename "$pkgpath")

    if [ -f "$setup_file" ]; then
        echo "Running: $pkgpath"
        bash "$setup_file"
    fi
}

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
    package_before_install "$package"

    echo "Create links for $pkg"
    stow -d stow -t $HOME $pkg

    package_after_install "$package"
done

os="$(uname)"
packages="$(ls -d ./stow/$os/*)"
echo "Installing packages for $os"
for package in $packages; do
    pkg=$(basename "$package")
    if [ "install.sh" = "$pkg" ]; then
        continue
    fi

    package_before_install "$package"

    echo "Create links for $pkg"
    stow -d "stow/$os" -t $HOME $pkg

    package_after_install "$package"
done
