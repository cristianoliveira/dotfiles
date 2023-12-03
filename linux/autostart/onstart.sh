#!/bin/bash
#
#  USAGE adds this to the crontab
#
#  sudo ln -s $HOME/.dotfiles/linux/autostart/onlogin /var/opt/onlogin
#
#  crontab -u $USER $HOME/.dotfiles/linux/autostart/crontab-boot
#

echo "Remapping capsolock"

setxkbmap -option caps:ctrl_modifier # Make capslock behave like ctrl
setxkbmap -option grp:shifts_toggle # Make shift switch between us and ru
setxkbmap -option altwin:swap_alt_win # Swap Alt and Win keys for pc behave like mac

# Remove previously running instances
# killall xcape

# if file ~/.custom-remap.sh exists, run it
if [ -f ~/.custom-remap.sh ]; then
  ~/.custom-remap.sh
fi
xcape -e 'Caps_Lock=Escape'
