# Purpose

`bin/` owns standalone executable helpers for system checks, window and terminal workflows, and small daily automation.

# Boundaries

Keep scripts here independent and focused on one command-line task. Nix configuration belongs to [nix](nix/AGENTS.md); editor-specific checks belong to [nvim](nvim/AGENTS.md); tool configuration belongs to its owning module.

# Connections

- [Nix system state](nix/AGENTS.md): `nix-check` validates the flake and platform configuration.
- [Neovim](nvim/AGENTS.md): `nvim-check` loads the editor configuration headlessly.
- [Tmux](tmux/AGENTS.md): terminal helpers invoke tmux sessions, panes, and popups.

# Placement

Add a helper here when it is a reusable executable with a narrow shell boundary. Keep configuration declarations and lifecycle hooks in their owning module instead of turning this directory into a general library.
