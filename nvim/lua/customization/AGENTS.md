# Purpose

`nvim/lua/customization/` owns editor behavior layered on top of plugin setup: commands, autocommands, helper functions, mappings, settings, and local plugins.

# Boundaries

Keep third-party registration in [nvim/lua/plugins](nvim/lua/plugins/AGENTS.md). Keep startup composition in [nvim/lua](nvim/lua/AGENTS.md). Within this module, put each behavior in its narrowest child area: [commands](nvim/lua/customization/commands/AGENTS.md), [mappings](nvim/lua/customization/mappings/AGENTS.md), [settings](nvim/lua/customization/settings/AGENTS.md), [utils](nvim/lua/customization/utils/AGENTS.md), or [local plugin integrations](nvim/lua/customization/plugins/AGENTS.md).

# Connections

- [Lua composition layer](nvim/lua/AGENTS.md): invokes this customization loader after plugin registration.
- [Plugin specifications](nvim/lua/plugins/AGENTS.md): provides plugin APIs consumed by customization.
- [Commands](nvim/lua/customization/commands/AGENTS.md): owns user commands exposed by the editor.
- [Mappings](nvim/lua/customization/mappings/AGENTS.md): owns key-driven entry points into commands and plugins.
- [Settings](nvim/lua/customization/settings/AGENTS.md): owns editor and plugin configuration.
- [Utilities](nvim/lua/customization/utils/AGENTS.md): supplies shared helper behavior to customization modules.
- [Local plugin integrations](nvim/lua/customization/plugins/AGENTS.md): owns repository-specific glue around selected plugins.

# Placement

Add behavior here only when it changes the editor experience. Choose a child module by ownership: commands expose named actions, mappings expose key bindings, settings configure state, and utilities provide reusable support without registering user-facing behavior.
