# Purpose

`nvim/lua/customization/settings/` owns editor options and plugin setup that establish the Neovim working environment, including LSP, completion, projection, curl, and diff settings.

# Boundaries

User commands belong in [commands](../commands/AGENTS.md); key bindings belong in [mappings](../mappings/AGENTS.md); reusable support belongs in [utils](../utils/AGENTS.md).

# Connections

- [Customization](../AGENTS.md): loads settings after the other customization registries.
- [Plugin specifications](../../plugins/AGENTS.md): provides plugin APIs configured here.
- [Commands](../commands/AGENTS.md): may expose commands for configured tools.

# Placement

Add a file here when it configures persistent editor or plugin state. Keep transient actions and key-driven behavior in their owning child modules.
