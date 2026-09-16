# Purpose

`nvim/lua/customization/utils/` owns reusable Lua support for customization modules, including command execution, asynchronous jobs, formatting, and Vim API helpers.

# Boundaries

User-facing commands belong in [commands](../commands/AGENTS.md); mappings belong in [mappings](../mappings/AGENTS.md); persistent configuration belongs in [settings](../settings/AGENTS.md).

# Connections

- [Customization](../AGENTS.md): provides the shared helper boundary for editor behavior.
- [Commands](../commands/AGENTS.md): consumes helpers while implementing named actions.
- [Mappings](../mappings/AGENTS.md): consumes selection and editor API helpers.

# Placement

Add a utility only when more than one customization concern benefits from the abstraction. Keep registration, key bindings, and command-specific policy in their owning modules.
