.PHONY: setup osx linux

setup:
	sh ./setup.sh

ssh:
	sh ./ssh-key.sh

linux:
	sh ./linux-install.sh

osx:
	sh ./osx-install.sh

osx-karabiner:
	cp -rf ~/.dotfiles/resources/karabiner ~/.config/
