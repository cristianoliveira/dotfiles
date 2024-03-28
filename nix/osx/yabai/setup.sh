#!/bin/sh

echo "Setting up yabai - tiling window manager"

# Link yabai configuration
mv $HOME/.yabairc $HOME/.yabairc.bak
mv $HOME/.skhdrc $HOME/.skhdrc.bak
ln -sf $HOME/.dotfiles/nix/osx/yabai/yabairc $HOME/.yabairc

ln -sf $HOME/.dotfiles/nix/osx/yabai/skhdrc $HOME/.skhdrc

# Installing via nix doesn't allow changing the config file path
sudo mv /etc/skhdrc /etc/skhdrc.bak
sudo ln -sf $HOME/.dotfiles/nix/osx/yabai/skhdrc /etc/skhdrc

echo "yabai setup complete"
