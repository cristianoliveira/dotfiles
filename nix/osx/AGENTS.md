# Purpose

`nix/osx/` owns the Darwin system composition: macOS defaults, applications, shortcuts, window management, virtualization, and macOS installation adapters.

# Boundaries

Keep Darwin-specific declarations and setup here. Shared packages and environment belong in [nix/shared](nix/shared/AGENTS.md); Linux behavior belongs in [nix/nixos](nix/nixos/AGENTS.md); flake-level selection belongs in [nix](nix/AGENTS.md). Browser routing and Alfred preferences are separate adapters under this module.

# Connections

- [Nix system composition](nix/AGENTS.md): selects `osx/configuration.nix` as the Darwin module root.
- [Shared Nix modules](nix/shared/AGENTS.md): supplies common developer, shell, environment, and home-configuration behavior.
- [Finicky adapter](nix/osx/finicky/AGENTS.md): consumes browser-routing configuration and installs the user-level Finicky file.
- [Alfred adapter](nix/osx/alfred/AGENTS.md): owns the exported Alfred preference bundle.

# Placement

Add a declaration here when it targets Darwin APIs, services, defaults, or applications. Keep browser and launcher-specific exported configuration in their adapter guides, and put cross-platform behavior in [nix/shared](nix/shared/AGENTS.md).
