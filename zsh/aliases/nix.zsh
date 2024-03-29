alias nss="nix-shell --run 'zsh' shell.nix"
alias nsh="nix-shell --run 'zsh' shell.nix"

alias denv="echo 'use nix' > .envrc && direnv allow"
alias denvrm="rm .envrc"
