alias nss="nix-shell --run 'zsh' shell.nix"
alias nsh="nix-shell --run 'zsh' shell.nix"

alias denv="echo 'use nix' > .envrc && direnv allow"
# Use flake
alias denvf="echo 'use flake' > .envrc && direnv allow"
# Use nix-shell
alias denvs="echo 'use nix' > .envrc && direnv allow"
alias denvrm="rm .envrc"

alias dallow="direnv allow"
alias disallow="direnv disallow"
