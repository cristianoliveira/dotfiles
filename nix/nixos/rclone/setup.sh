#!/usr/bin/env bash

set -e

echo "Credentials should be in your password manager"
echo "Create a file named rclone.conf in your home directory"
echo "and paste the content of your rclone configuration file"
echo "from your password manager"
echo ""

read -p "Press enter to continue"
if [ ! -f $HOME/rclone.conf ]; then
  echo "rclone.conf not found in $HOME"
else
  mv $HOME/rclone.conf $HOME/.config/rclone/rclone.conf

  echo "rclone.conf moved to $HOME/.config/rclone/rclone.conf"
  echo "try: 'rclone sync gdrive:/notes $HOME/notes'"
fi

