#!/usr/bin/env bash

set -euo pipefail

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


## Package before uninstall
# If the package folder contains an $pkg/before_uninstall.sh file,
# it will be executed before the package is unlinked.
function package_before_uninstall() {
    local pkgpath="$1"
    local setup_file="$pkgpath/before_uninstall.sh"
    local pkg=$(basename "$pkgpath")

    if [ -f "$setup_file" ]; then
        echo "Running: $pkgpath"
        bash "$setup_file"
    fi
}

## Package after uninstall
# If the package folder contains an $pkg/after_uninstall.sh file
# it will be executed after the package is unlinked.
function package_after_uninstall() {
    local pkgpath="$1"
    local setup_file="$pkgpath/after_uninstall.sh"
    local pkg=$(basename "$pkgpath")

    if [ -f "$setup_file" ]; then
        echo "Running: $pkgpath"
        bash "$setup_file"
    fi
}
