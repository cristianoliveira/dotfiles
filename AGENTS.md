# Purpose

This repository defines a reproducible development environment for NixOS and macOS, keeping packages, operating-system settings, shell tools, and editor workflows aligned across both systems.

# Architecture

- [nix](nix/AGENTS.md) is the composition root for NixOS and nix-darwin system state. Shared modules are selected by the platform configuration.
- [stow](stow/AGENTS.md) materializes home-directory configuration and runs package hooks; it does not own tool behavior.
- [nvim](nvim/AGENTS.md), [tmux](tmux/AGENTS.md), [zsh](zsh/AGENTS.md), and [git](git/AGENTS.md) own tool-specific configuration.
- [bin](bin/AGENTS.md) contains standalone helpers used by the configuration and daily workflows.

# Modules

- [Nix system state](nix/AGENTS.md): platform composition, shared modules, and package overlays.
- [Home symlink layout](stow/AGENTS.md): shared and platform-specific Stow packages and lifecycle hooks.
- [Neovim](nvim/AGENTS.md): editor startup, plugins, custom commands, mappings, and settings.
- [Tmux](tmux/AGENTS.md): terminal multiplexer configuration, mappings, and popup scripts.
- [Zsh](zsh/AGENTS.md): shell startup, aliases, functions, and settings.
- [Git](git/AGENTS.md): Git configuration, aliases, ignore rules, and setup.
- [Helpers](bin/AGENTS.md): executable scripts and small command-line helpers.

# Placement

Put operating-system state in [nix](nix/AGENTS.md), home-directory placement in [stow](stow/AGENTS.md), and behavior for a specific tool in its owning module. Add a new top-level module only when a responsibility has a distinct owner and dependency boundary; otherwise extend the nearest existing guide.
