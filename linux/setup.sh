# Link an shared script to be used with ./autostart/MyDotfiles.desktop
echo "Configuring autostart"
bash $HOME/.dotfiles/linux/autostart/setup.sh

echo "Configuring i3 config"
if [ ! -d "$HOME/.config/i3" ]; then
  ln -s $HOME/.dotfiles/linux/i3 $HOME/.config/
fi

echo "tmux system-wide installed"
# To keep consistency between linux and osx for alacritty configs
if [ ! -f "/usr/bin/tmux" ]; then
  sudo ln -s /usr/bin/tmux /usr/local/bin/
fi
