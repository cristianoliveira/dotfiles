#!/usr/bin/env bash
set -euo pipefail

OS="${1:-}"
if [ "$#" -ne 1 ]; then
  printf 'Usage: %s {osx|linux}\n' "$0" >&2
  exit 2
fi

case "$OS" in
  osx|linux) ;;
  *)
    printf 'Unsupported OS: %s\nUsage: %s {osx|linux}\n' "$OS" "$0" >&2
    exit 2
    ;;
esac

echo "Cloning dotfiles with pinned submodules"
nix-shell \
  -p git vim \
  --command "git clone --recurse-submodules https://github.com/cristianoliveira/dotfiles.git ~/.dotfiles"

cd "$HOME/.dotfiles"

case "$OS" in
  osx)
    echo "Installing for macOS"
    ./nix/osx/setup.sh
    ;;
  linux)
    echo "Installing for Linux"
    ./nix/nixos/setup.sh
    ;;
esac
