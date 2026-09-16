# Purpose

`nvim/lua/customization/commands/` owns user-facing Neovim commands and the command implementations they invoke, including Git, review, search, note, clipboard, and editing actions.

# Boundaries

Key bindings belong in [mappings](../mappings/AGENTS.md); shared implementation helpers belong in [utils](../utils/AGENTS.md); plugin registration belongs in [nvim/lua/plugins](../../plugins/AGENTS.md).

# Connections

- [Customization](../AGENTS.md): loads the command registry during editor startup.
- [Mappings](../mappings/AGENTS.md): routes keyboard input to command and plugin actions.
- [Utilities](../utils/AGENTS.md): supplies reusable command support where needed.

# Placement

Add a module here when the editor should expose a named command. Keep command registration near its implementation and avoid placing general-purpose helpers in this directory.
