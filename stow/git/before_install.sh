#!/usr/bin/env bash

set -e

echo "Setting up 'git' configurations."

if [ -f "$HOME"/.gitconfig.user ]; then
  echo "[WARN] ~/.gitconfig.user already exists. Please remove it before running this script."
else
  # ask for user name and email
  echo "---- Setting up GIT ----"
  echo ">>> Please enter your git user name:"
  read git_user_name
  echo ">>> Please enter your git email:"
  read git_email

  echo "export GIT_USER_NAME=$git_user_name" >> "$HOME/.env"
  echo "export GIT_EMAIL=$git_email" >> "$HOME/.env"

  if [ -z "$git_user_name" ] || [ -z "$git_email" ]; then
    echo "Please provide a valid git user name and email."
    exit 1
  fi

  ## Ignore generating ssh key if it already exists
  echo "Checking SSH key..."
  SSHKEY="$HOME/.ssh/id_ed25519"
  if [ -f "$SSHKEY" ]; then
    echo "SSH key already exists."
  else
    ssh-keygen -t ed25519 -C "$git_email" -f "$SSHKEY"
  fi

  echo "---------------------------"
  cat "$SSHKEY.pub"
  echo "---------------------------"
  echo ">>> Please adds the content above to your github account."
  echo ">>> Copy and add the content above to https://github.com/settings/ssh/new"
  echo "Press any key to continue."
  read _git_key_added


  # replace placeholders in gitconfig
  cp $HOME/.dotfiles/git/gitconfig.user $HOME/.gitconfig.user

  # For Linux
  if [ "$(uname)" == "Linux" ]; then
    sed -i "s/__git_username__/$git_user_name/g" $HOME/.gitconfig.user
    sed -i "s/__git_email__/$git_email/g" $HOME/.gitconfig.user
  else
    sed -i '' "s/__git_username__/$git_user_name/g" $HOME/.gitconfig.user
    sed -i '' "s/__git_email__/$git_email/g" $HOME/.gitconfig.user
  fi
fi
