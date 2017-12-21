# Link an shared script to be used with ./autostart/MyDotfiles.desktop
sudo ln -s $HOME/.dotfiles/linux/onlogin.sh /usr/local/share/onlogin.sh
ln -s $HOME/.dotfiles/linux/autostart/MyDotfiles.desktop ~/.config/autostart/MyDotfiles.desktop

mv $HOME/.profile $HOME/.profile-old
ln -s $HOME/.dotfiles/linux/profile $HOME/.profile

sh $HOME/.dotfiles/linux/install-packages.sh

# Change key delay rate and repeat
xset r rate 180 40

