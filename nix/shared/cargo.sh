#!/usr/bin/env bash

# See https://archive.ph/NgMxV
echo "Enabling git-fetch-with-cli for cargo"
echo "
[net]
git-fetch-with-cli = true
" >> ~/.cargo/config
