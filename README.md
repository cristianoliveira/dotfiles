# dotfiles

My dotfiles for setting up a new development environment. :package: :sunglasses: :sunglasses: :package:

![Screenshot 2023-09-15 at 09 13 35](https://github.com/cristianoliveira/dotfiles/assets/3959744/d7ad7fe0-6ce7-4825-aa95-eb5e6ee98b3d)

# What do I use?

  - ZSH (oh-my-zsh)
  - Neovim
  - Tmux
  - Allacrity 
  - A lot of pre-installed apps. See in: `osx/Brewfile` or `linux/packages.txt`

### I work mostly with

  - Typescript & Javascript (React & Node, et all)
  - HTML & CSS
  - Rust
  - Golang

  A bunch of 

  - Bash

  And a bit of

  - Ruby
  - Python

## Installing

### Prerequisites

 - Generate your [ssh key and add to your github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
 - In short `ssh-keygen -t ed25519 -C "your_email@example.com"` and add the key to your github account.

In short:
```bash
curl https://raw.githubusercontent.com/cristianoliveira/dotfiles/main/install.sh | bash -s - osx
# or
curl https://raw.githubusercontent.com/cristianoliveira/dotfiles/main/install.sh | bash -s - linux
```

Or step by step

```bash
git clone git@github.com:cristianoliveira/dotfiles.git ~/.dotfiles

cd ~/.dotfiles

# For linux users
make linux
# or
make osx

# Updating and setup
make setup
```
