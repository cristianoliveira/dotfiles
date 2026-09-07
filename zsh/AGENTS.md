# Purpose

`zsh/` owns interactive shell startup and its user-level aliases, functions, and settings.

# Boundaries

Shell behavior belongs here. Packages and environment declarations belong in [nix](nix/AGENTS.md); home-directory linking belongs in [stow](stow/AGENTS.md); standalone commands belong in [bin](bin/AGENTS.md).

# Connections

- [Nix system state](nix/AGENTS.md): supplies the shell, packages, and environment values used at startup.
- [Home symlink layout](stow/AGENTS.md): links the shell files into the home directory.
- [Helpers](bin/AGENTS.md): provides executable commands exposed through the shell.
- [Tmux](tmux/AGENTS.md): is the terminal environment in which the shell commonly runs.

# Placement

Put startup ordering and shell-wide exports in `zsh/zshrc`; put reusable aliases, functions, or settings in their matching child directory. Keep system installation and package selection outside this module.
