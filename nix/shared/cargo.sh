#!/usr/bin/env bash

set -e # This is necessary to catch errors in commands
set -o pipefail # This is necessary to catch errors in commands piped together

# See https://archive.ph/NgMxV
echo "Enabling git-fetch-with-cli for cargo"
echo "
[net]
git-fetch-with-cli = true
" >> ~/.cargo/config
