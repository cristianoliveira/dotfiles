# Purpose

`nvim/lua/customization/mappings/` owns keyboard mappings that connect normal, visual, terminal, Git, LSP, search, and plugin workflows to Neovim actions.

# Boundaries

Named commands belong in [commands](../commands/AGENTS.md); editor state configuration belongs in [settings](../settings/AGENTS.md); reusable functions belong in [utils](../utils/AGENTS.md).

# Connections

- [Customization](../AGENTS.md): loads the mapping registry during startup.
- [Commands](../commands/AGENTS.md): provides named actions that mappings can invoke.
- [Utilities](../utils/AGENTS.md): provides mapping helpers and selection support.

# Placement

Add a mapping here when the behavior is intentionally keyboard-driven. Keep the implementation in its command or utility owner and make the mapping a thin route to it.
