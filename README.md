# dotfiles
My dotfiles for setting up a new dev environment. :package: :sunglasses: :sunglasses: :package:

# What do I use?

  - ZSH (oh-my-zsh)
  - Nvim 0.5
  - Tmux 2.5

  And a lot of pre installed apps. See in: `osx/Brewfile` or `linux/packages.txt`

  I work mostly with:

  - Javascript and Reactjs
  - Rust
  - Golang

  And a bit of

  - Ruby
  - Python

# Installing

```bash
git clone git@github.com:cristianoliveira/dotfiles.git ~/.dotfiles

# For linux users
make linux
# or
# sh ~/.dotfiles/linux-install.sh

# For mac users
make osx

# or
# sh ~/.dotfiles/osx-install.sh

# Updating and setup
make setup
make ssh
```
