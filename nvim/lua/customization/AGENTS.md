# Purpose

`nvim/lua/customization/` owns editor behavior layered on top of plugin setup: commands, autocommands, helper functions, mappings, settings, and local plugins.

# Boundaries

Keep third-party registration in [nvim/lua/plugins](../plugins/AGENTS.md). Keep startup composition in [nvim/lua](../AGENTS.md). Within this module, put each behavior in its narrowest child area: [commands](commands/AGENTS.md), [mappings](mappings/AGENTS.md), [settings](settings/AGENTS.md), [utils](utils/AGENTS.md), or [local plugin integrations](plugins/AGENTS.md).

# Connections

- [Lua composition layer](../AGENTS.md): invokes this customization loader after plugin registration.
- [Plugin specifications](../plugins/AGENTS.md): provides plugin APIs consumed by customization.
- [Commands](commands/AGENTS.md): owns user commands exposed by the editor.
- [Mappings](mappings/AGENTS.md): owns key-driven entry points into commands and plugins.
- [Settings](settings/AGENTS.md): owns editor and plugin configuration.
- [Utilities](utils/AGENTS.md): supplies shared helper behavior to customization modules.
- [Local plugin integrations](plugins/AGENTS.md): owns repository-specific glue around selected plugins.

# Placement

Add behavior here only when it changes the editor experience. Choose a child module by ownership: commands expose named actions, mappings expose key bindings, settings configure state, and utilities provide reusable support without registering user-facing behavior.
