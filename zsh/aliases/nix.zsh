alias nss="nix-shell --run 'zsh' shell.nix"
alias nsh="nix-shell --run 'zsh' shell.nix"

alias denv="echo 'use nix' > .envrc && direnv allow"
# Use flake
alias dusef="echo 'use flake' > .envrc && direnv allow"
# Use nix
alias dusen="echo 'use nix' > .envrc && direnv allow"
# Load .env if it exists
alias duseenv="echo 'dotenv_if_exists' >> .envrc && direnv allow"

alias denvrm="rm .envrc"

alias dallow="direnv allow"
alias disallow="direnv disallow"

alias dupd="touch .envrc"
alias dupdate="touch .envrc"
