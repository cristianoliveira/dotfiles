# Link an shared script to be used with ./autostart/MyDotfiles.desktop
echo "Configuring autostart"
bash $HOME/.dotfiles/linux/autostart/setup.sh

echo "Configuring i3 config"
ln -s $HOME/.dotfiles/linux/i3 $HOME/.config/i3
