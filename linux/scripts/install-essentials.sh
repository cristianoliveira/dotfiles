#!/bin/bash
#
echo "installing essentials"

## essentials
sudo apt update
sudo apt-get install git gcc make pkg-config libx11-dev libxtst-dev libxi-dev wget curl -y

## To run AppImages app.appimage
sudo apt install libfuse2
mkdir -p $HOME/Applications

## Windows manager
echo "installing windows manager"
if ! which i3 &> /dev/null; then
  sudo apt install xorg lightdm lightdm-gtk-greeter i3-wm \
    i3lock i3status i3blocks dmenu -y

  sudo systemctl enable lightdm.service
fi

## laucher (alfred)
echo "installing laucher"
if ! command -v ulauncher &> /dev/null; then
  sudo add-apt-repository universe -y && \ 
    sudo add-apt-repository ppa:agornostal/ulauncher -y \
    sudo apt update && \
    sudo apt install ulauncher -y
fi

## keyboard mappings (karabiner-elements)
sudo apt install xcape -y

## Terminal 
echo "installing terminal"
if ! command -v alacritty &> /dev/null; then
  sudo add-apt-repository ppa:aslatter/ppa && \
    sudo apt update && \
    sudo apt install alacritty -y
fi

# Bitwarden
# if Bitwarden is not present in $HOME/Applications install it
echo "installing Bitwarden"
if [ ! -f "$HOME/Applications/Bitwarden.AppImage" ]; then
  wget https://vault.bitwarden.com/download/\?app\=desktop\&platform\=linux $HOME/Applications/Bitwarden.AppImage
fi

# sudo snap install bitwarden

# neovim
echo "installing neovim"
if [ ! -f "$HOME/Applications/nvim.appimage" ]; then
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage
  mv nvim.appimage $HOME/Applications/nvim.appimage
  sudo ln -s $HOME/Applications/nvim.appimage /usr/bin/nvim
fi

echo "tmux"
if ! command -v tmux &> /dev/null; then
  sudo apt-get install tmux -y
fi

echo "asdf"
if ! command -v asdf &> /dev/null; then
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.13.1
  . "$HOME/.asdf/asdf.sh"
fi

echo "fzf"
if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
fi

echo "ripgrep"
if ! command -v rg &> /dev/null; then
  sudo apt install ripgrep -y
fi

echo "jq"
if ! command -v jq &> /dev/null; then
  sudo apt install jq -y
fi

echo "rust"
if ! command -v cargo &> /dev/null; then
  curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
fi

echo "docker"
if ! command -v docker &> /dev/null; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/download.docker.com.gpg
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  sudo apt update
  sudo apt -qq install docker-ce -y
fi

if ! command -v docker-compose &> /dev/null; then
  sudo apt update
  sudo apt -qq install docker-compose -y
fi

echo "diff-so-fancy"
if ! command -v diff-so-fancy &> /dev/null; then
  sudo snap install diff-so-fancy -y
fi
