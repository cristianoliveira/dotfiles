# Purpose

`nix/osx/alfred/` owns the exported Alfred preferences bundle used for launcher and remote-control workflows on macOS.

# Boundaries

Treat the preference bundle as application-owned exported configuration. Darwin system settings belong in [nix/osx](nix/osx/AGENTS.md); executable helper behavior belongs in [bin](bin/AGENTS.md).

# Connections

- [macOS modules](nix/osx/AGENTS.md): provides the platform-specific home for this adapter.
- [Helpers](bin/AGENTS.md): may supply scripts invoked by launcher workflows.

# Placement

Update the Alfred export when launcher workflow structure or preferences change. Put reusable shell automation in [bin](bin/AGENTS.md), not inside the exported preference data.
