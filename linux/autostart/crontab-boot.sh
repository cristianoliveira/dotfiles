#!/bin/bash
#
#  USAGE adds this to the crontab
#
#  sudo ln -s /home/cristianoliveira/.dotfiles/linux/autostart/crontab-boot.sh /var/opt/autostart
#
#  crontab -u $USER $HOME/.dotfiles/linux/autostart/crontab-boot
#
#
#

echo "Remapping capsolock"

setxkbmap -option caps:ctrl_modifier -option grp:shifts_toggle &

#
# # Remove previously running instances
# # killall xcape
#
xcape -e 'Caps_Lock=Escape'
