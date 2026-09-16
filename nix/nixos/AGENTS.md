# Purpose

`nix/nixos/` owns the Linux system composition: hardware, desktop services, applications, input mappings, and NixOS-only system services.

# Boundaries

Keep Linux-only declarations here. Shared packages and environment belong in [nix/shared](../shared/AGENTS.md); Darwin behavior belongs in [nix/osx](../osx/AGENTS.md); flake-level selection belongs in [nix](../AGENTS.md).

# Connections

- [Nix system composition](../AGENTS.md): selects `nixos/configuration.nix` as the NixOS module root.
- [Shared Nix modules](../shared/AGENTS.md): supplies common developer, shell, environment, and home-configuration behavior.
- [Helpers](../../bin/AGENTS.md): provides executable checks used around system configuration.

# Placement

Add a module here when its declaration depends on NixOS services, Linux hardware, or the Linux desktop. Keep reusable declarations in [nix/shared](../shared/AGENTS.md) instead of duplicating them.
