# Purpose

`nix/overlays/` owns package-set extensions used by the flake, including wrapped packages, nightly packages, and packages sourced from the custom package input.

# Boundaries

Keep package selection and replacement logic here. System declarations belong in [nix](nix/AGENTS.md) and the platform module that consumes the package; shared package lists belong in [nix/shared](nix/shared/AGENTS.md).

# Connections

- [Nix system composition](nix/AGENTS.md): imports the overlay set while constructing both platform package sets.
- [Shared Nix modules](nix/shared/AGENTS.md): consumes the resulting package attributes for cross-platform tools.

# Placement

Add an overlay when a package needs a modified source, wrapper, or channel-specific version. Do not place system settings or application configuration here.
