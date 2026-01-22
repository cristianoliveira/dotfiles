.PHONY: help
help: ## Lists the available commands. Add a comment with '##' to describe a command.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST)\
		| sort\
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Run the setup script (stow)
	@bash ./stow/install.sh

.PHONY: ssh
ssh: ## Run the ssh-key script to generate a new ssh key
	@bash ./nix/shared/ssh-key.sh

.PHONY: linux
linux: ## Run the linux setup to setup a new nixos instance
	@bash ./nix/install.sh

.PHONY: osx
osx: ## Run the osx setup to setup a new macos instance
	@bash ./nix/install.sh

.PHONY: watch
watch: ## Run the watch script to watch for changes in the dotfiles
	@fzz

.PHONY: nix
nix: ## Rebuild the system using nix installing all the packages
	SKIP_COMMIT=1 nix/rebuild.sh

.PHONY: nixos
nixos: ## Rebuild the system using nix installing all the packages
	SKIP_COMMIT=1 nix/rebuild.sh

.PHONY: nixos
nixos-cleanup: ## Cleanup old generations of nixos (older than 5 days)
	sudo nix-env --delete-generations --profile /nix/var/nix/profiles/system 5d

.PHONY: sway-reload
sway-reload: ## Reload sway configuration
	swaymsg reload

.PHONY: nix-setup
nix-setup: ## Run the nix setup script
	@bash ./nix/setup.sh

.PHONY: stow
stow: ## Create links for .config files using stow
	@bash ./stow/install.sh

.PHONY: restow
restow: ## Create links for .config files using stow
	RESTOW=true bash ./stow/install.sh

.PHONY: nvim
nvim: ## Headless check that Neovim config loads cleanly
	@./bin/nvim-check

.PHONY: check-symlinks
check-symlinks: ## Check for broken symlinks in the repository
	@./bin/check-symlinks

.PHONY: check-nix
check-nix: ## Validate Nix configuration syntax and flake evaluation
	@./bin/nix-check

.PHONY: check-symlinks
check-symlinks: ## Check for broken symlinks in the repository
	@./bin/check-symlinks
