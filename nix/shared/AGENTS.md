# Purpose

`nix/shared/` owns Nix modules imported by both platform compositions, including developer tooling, environment values, security, and home-configuration integration.

# Boundaries

Only cross-platform behavior belongs here. Linux-specific services belong in [nix/nixos](nix/nixos/AGENTS.md), macOS-specific settings belong in [nix/osx](nix/osx/AGENTS.md), and package replacement logic belongs in [nix/overlays](nix/overlays/AGENTS.md).

# Connections

- [Nix system composition](nix/AGENTS.md): platform configurations import these modules for shared behavior.
- [NixOS modules](nix/nixos/AGENTS.md): consumes shared packages and environment declarations in the Linux build.
- [macOS modules](nix/osx/AGENTS.md): consumes shared packages and environment declarations in the Darwin build.
- [Stow layout](stow/AGENTS.md): the shared Stow module exposes home-directory configuration integration.

# Placement

Place a setting here only when it can apply to both supported platforms without platform conditionals. Split platform-specific behavior into the corresponding platform guide.
