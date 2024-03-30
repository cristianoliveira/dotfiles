#!/bin/sh

echo "Setting up git configurations."

mv -f "$HOME"/.gitconfig "$HOME/.gitconfig.bkp-$(date +%s)"
mv -f "$HOME"/.gitignore "$HOME/.gitignore.bkp-$(date +%s)"

ln -s "$HOME"/.dotfiles/git/gitconfig "$HOME"/.gitconfig
ln -s "$HOME"/.dotfiles/git/gitignore "$HOME"/.gitignore

# ask for user name and email
echo "Please enter your git user name:"
read git_user_name
echo "Please enter your git email:"
read git_email

if [ -z "$git_user_name" ] || [ -z "$git_email" ]; then
  echo "Please provide a valid git user name and email."
  exit 1
fi

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
