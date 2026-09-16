# Purpose

`scripts/` owns repository-level validation and maintenance tools for the AGENTS.md guidance graph.

# Boundaries

Keep tooling here that checks the structure and navigability of the guides. It does not own the guidance content itself; that remains in each module's `AGENTS.md`. Operational setup scripts belong in the repository root or in [nix](../nix/AGENTS.md); home-directory installation scripts belong in [stow](../stow/AGENTS.md).

# Connections

- [Repository guide](../AGENTS.md): is the root map validated by these scripts.
- [Module guides](../bin/AGENTS.md): every local `AGENTS.md` is checked for link reachability.

# Placement

Add a script here when it validates, audits, or repairs the guide graph. Keep one-off automation in [bin](../bin/AGENTS.md) or in the module that owns the behavior being automated.
