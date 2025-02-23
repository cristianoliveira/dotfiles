.PHONY: help
help: ## Lists the available commands. Add a comment with '##' to describe a command.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST)\
		| sort\
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Run the setup script
	@bash ./setup.sh

.PHONY: ssh
ssh: ## Run the ssh-key script to generate a new ssh key
	@bash ./nix/shared/ssh-key.sh

.PHONY: linux
linux: ## Run the linux setup to setup a new nixos instance
	@bash ./nix/nixos/setup.sh

.PHONY: osx
osx: ## Run the osx setup to setup a new macos instance
	@bash ./nix/osx/setup.sh

.PHONY: watch
watch: ## Run the watch script to watch for changes in the dotfiles
	@fzz

.PHONY: nixos
nixos: ## 
	SKIP_COMMIT=1 nix/rebuild.sh
