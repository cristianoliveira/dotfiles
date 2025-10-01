#!/usr/bin/env bash

if [ ! -d "$HOME/Applications" ]; then
    echo "Creating ~/Applications directory"
    mkdir -p $HOME/Applications
fi
