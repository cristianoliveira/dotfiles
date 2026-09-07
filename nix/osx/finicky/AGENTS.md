# Purpose

`nix/osx/finicky/` owns the macOS Finicky browser-routing adapter and its setup hook.

# Boundaries

Keep URL matching and browser selection in the Finicky configuration. Darwin package and system settings belong in [nix/osx](nix/osx/AGENTS.md); generic browser behavior does not belong in the NixOS modules.

# Connections

- [macOS modules](nix/osx/AGENTS.md): provides the Darwin context and installation route for this adapter.

# Placement

Add a rule here when it changes how Finicky routes a URL. Keep unrelated browser automation or system defaults in their owning modules.
