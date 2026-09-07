# Purpose

`nvim/lua/customization/commands/` owns user-facing Neovim commands and the command implementations they invoke, including Git, review, search, note, clipboard, and editing actions.

# Boundaries

Key bindings belong in [mappings](nvim/lua/customization/mappings/AGENTS.md); shared implementation helpers belong in [utils](nvim/lua/customization/utils/AGENTS.md); plugin registration belongs in [nvim/lua/plugins](nvim/lua/plugins/AGENTS.md).

# Connections

- [Customization](nvim/lua/customization/AGENTS.md): loads the command registry during editor startup.
- [Mappings](nvim/lua/customization/mappings/AGENTS.md): routes keyboard input to command and plugin actions.
- [Utilities](nvim/lua/customization/utils/AGENTS.md): supplies reusable command support where needed.

# Placement

Add a module here when the editor should expose a named command. Keep command registration near its implementation and avoid placing general-purpose helpers in this directory.
