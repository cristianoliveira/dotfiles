# Purpose

`nix/` composes the reproducible machine environment for NixOS and macOS: flake inputs and outputs, shared modules, platform modules, and package overlays.

# Boundaries

The flake selects a platform composition. Cross-platform declarations belong in [nix/shared](shared/AGENTS.md); Linux-only declarations belong in [nix/nixos](nixos/AGENTS.md); Darwin-only declarations belong in [nix/osx](osx/AGENTS.md); package overrides belong in [nix/overlays](overlays/AGENTS.md). Home-directory placement is owned by [stow](../stow/AGENTS.md).

# Connections

- [NixOS modules](nixos/AGENTS.md): provides the Linux system module set selected by the flake.
- [macOS modules](osx/AGENTS.md): provides the Darwin system module set selected by the flake.
- [Shared Nix modules](shared/AGENTS.md): supplies behavior imported by both platform compositions.
- [Package overlays](overlays/AGENTS.md): extends the package set before platform modules evaluate.
- [Stow layout](../stow/AGENTS.md): receives the shared home-configuration package through the Nix system configuration.

# Placement

Add composition and flake wiring here. Put a declaration in the narrowest platform or shared module that owns it; create a new module when the responsibility has independent lifecycle and ownership rather than adding another unrelated option to a broad configuration file.
