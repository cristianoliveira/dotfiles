# Link an shared script to be used with ./autostart/MyDotfiles.desktop
sudo ln -s ~/.dotfiles/linux/onlogin.sh /usr/local/share/onlogin.sh

sh ./install-packages.sh

# Change key delay rate and repeat
xset r rate 180 40

