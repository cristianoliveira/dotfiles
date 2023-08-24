# dotfiles

My dotfiles for setting up a new dev environment. :package: :sunglasses: :sunglasses: :package:

# What do I use?

  - ZSH (oh-my-zsh)
  - Neovim 
  - Tmux

  And a lot of pre-installed apps. See in: `osx/Brewfile` or `linux/packages.txt`

  I work mostly with:

  - Typescript & Javascript (React & Node, et all)
  - Rust
  - Golang

  A bunch of 

  - Bash

  And a bit of

  - Ruby
  - Python

# Installing

### Prerequisites

 - Generate your (ssh key and add to your github)[https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent]
 - In short `ssh-keygen -t ed25519 -C "your_email@example.com"` and add the key to your github account.

```bash
git clone git@github.com:cristianoliveira/dotfiles.git ~/.dotfiles

cd ~/.dotfiles

# For linux users
make linux
# or
make osx

# Updating and setup
make setup
make ssh
```
