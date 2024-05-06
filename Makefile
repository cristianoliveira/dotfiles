.PHONY: setup osx linux

setup:
	@bash ./setup.sh

ssh:
	@bash ./ssh-key.sh

linux:
	@bash ./nix/nixos/setup.sh

osx:
	@bash ./nix/osx/setup.sh

watch: 
	@fzz
