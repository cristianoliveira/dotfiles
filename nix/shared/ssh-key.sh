#!/bin/env bash

set -e  # fail on error

if [ -f ~/.ssh/id_ed25519 ]; then
  echo "SSH key already exists"
  read -rp "Do you want to overwrite it? (y/n) " ANSWER
  # If answer is No, exit
  if [[ ! $ANSWER =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

read -rp "Enter your email: " email

ssh-keygen -t ed25519 -C "$email"

echo "---------------------------"
cat ~/.ssh/id_ed25519.pub
echo "---------------------------"

echo "Copy and add the content above to https://github.com/settings/ssh/new"
