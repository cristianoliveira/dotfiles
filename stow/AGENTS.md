# Purpose

`stow/` owns the home-directory symlink layout for shared and platform-specific configuration packages, plus the lifecycle hooks that prepare those packages.

# Boundaries

This module decides what is linked and which package hooks run. Tool behavior belongs to [git](git/AGENTS.md), [zsh](zsh/AGENTS.md), [tmux](tmux/AGENTS.md), [nvim](nvim/AGENTS.md), or [bin](bin/AGENTS.md); system package declarations belong to [nix](nix/AGENTS.md).

# Connections

- [Nix system state](nix/AGENTS.md): installs or exposes the shared Stow integration.
- [Git configuration](git/AGENTS.md): receives the Git package setup hook and its source files.
- [Zsh configuration](zsh/AGENTS.md): links shell startup and component files.
- [Tmux configuration](tmux/AGENTS.md): links the multiplexer configuration and scripts.
- [Neovim](nvim/AGENTS.md): links the editor configuration into the expected home layout.
- [Helpers](bin/AGENTS.md): provides executable commands that linked configurations invoke.

# Placement

Change package contents or platform selection here when the home layout changes. Keep the linked tool's settings in that tool's module and keep hook behavior limited to installation-time preparation.
