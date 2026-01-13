#!/usr/bin/env bash

set -e

echo "After install ai"

# If Darwin, create a link to config file in $HOME/Application Support/aichat/config.yaml
if [ "$(uname)" = "Darwin" ]; then
    if [ -d "$HOME/Library/Application Support/aichat" ]; then
        # Skip if the directory already exists
        echo "Skipping aichat config file link, directory already exists"
    else
        ln -sf "$HOME/.config/aichat" "$HOME/Library/Application Support/"
    fi
else
    echo "Skipping aichat config file link for non-Darwin OS"
fi
