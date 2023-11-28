#!/bin/bash
#
#  USAGE adds this to the crontab
#
#  sudo ln -s $HOME/.dotfiles/linux/autostart/onlogin /var/opt/onlogin
#
#  crontab -u $USER $HOME/.dotfiles/linux/autostart/crontab-boot
#

echo "Remapping capsolock"

setxkbmap -option caps:ctrl_modifier -option grp:shifts_toggle

# Remove previously running instances
# killall xcape

xcape -e 'Caps_Lock=Escape'

# Swap Alt and Win keys for pc behave like mac
setxkbmap -option altwin:swap_alt_win
