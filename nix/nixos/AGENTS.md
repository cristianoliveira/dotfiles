# Purpose

`nix/nixos/` owns the Linux system composition: hardware, desktop services, applications, input mappings, and NixOS-only system services.

# Boundaries

Keep Linux-only declarations here. Shared packages and environment belong in [nix/shared](nix/shared/AGENTS.md); Darwin behavior belongs in [nix/osx](nix/osx/AGENTS.md); flake-level selection belongs in [nix](nix/AGENTS.md).

# Connections

- [Nix system composition](nix/AGENTS.md): selects `nixos/configuration.nix` as the NixOS module root.
- [Shared Nix modules](nix/shared/AGENTS.md): supplies common developer, shell, environment, and home-configuration behavior.
- [Helpers](bin/AGENTS.md): provides executable checks used around system configuration.

# Placement

Add a module here when its declaration depends on NixOS services, Linux hardware, or the Linux desktop. Keep reusable declarations in [nix/shared](nix/shared/AGENTS.md) instead of duplicating them.
