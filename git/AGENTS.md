# Purpose

`git/` owns the Git client configuration used after installation: the main config, aliases, ignore rules, and user-config template.

# Boundaries

Configuration and aliases belong here. Git setup and home-directory linking are installation concerns owned by [stow](stow/AGENTS.md); editor behavior remains in [nvim](nvim/AGENTS.md).

# Connections

- [Stow layout](stow/AGENTS.md): the Git package hook installs these files into the home directory and collects user identity values.
- [Neovim](nvim/AGENTS.md): Git commands select Neovim for editing and diff workflows.

# Placement

Add a Git alias or client setting here. Put interactive editor commands in [nvim](nvim/AGENTS.md), and put installation or backup behavior in [stow](stow/AGENTS.md).
