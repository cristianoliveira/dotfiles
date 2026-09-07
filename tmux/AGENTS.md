# Purpose

`tmux/` owns the terminal multiplexer configuration, key tables, popup workflows, reload/setup scripts, and the vendored `tmux-open` integration.

# Boundaries

Keep terminal-session behavior here. Reusable standalone commands belong in [bin](bin/AGENTS.md); shell startup belongs in [zsh](zsh/AGENTS.md); editor behavior belongs in [nvim](nvim/AGENTS.md).

# Connections

- [Home symlink layout](stow/AGENTS.md): installs the tmux configuration into the home directory.
- [Helpers](bin/AGENTS.md): supplies session and popup commands invoked by mappings.
- [Zsh](zsh/AGENTS.md): provides the shell used by popup workflows.
- [Neovim](nvim/AGENTS.md): is the default editor for copy-to-command workflows.

# Placement

Put key bindings and tmux options in the configuration or mappings. Put popup-specific scripts beside the tmux integration; promote a script to [bin](bin/AGENTS.md) only when it is useful outside tmux. The vendored `tmux-open/` tree is an adapter boundary and should not be edited for unrelated behavior.

The copy-mode and popup constraints are recorded in `tmux/DEVELOPMENT.md`.
