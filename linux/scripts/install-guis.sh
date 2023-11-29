#!/bin/sh

# Browsers

wget -O- https://deb.librewolf.net/keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/librewolf.gpg

sudo tee /etc/apt/sources.list.d/librewolf.sources << EOF > /dev/null
Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg
EOF

sudo apt update
sudo apt install librewolf -y

# Ulauncher (alfred)
sudo add-apt-repository ppa:agornostal/ulauncher
sudo apt update
sudo apt install ulauncher

# Bitwarden
snap install bitwarden

# Spotify
snap install spt

# Wallpapers
sudo apt install nitrogen -y
