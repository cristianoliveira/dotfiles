# Purpose

`nvim/lua/` is the Neovim Lua composition layer. It registers external plugins and loads the repository's editor customization during startup.

# Boundaries

Top-level plugin registration belongs in [nvim/lua/plugins](nvim/lua/plugins/AGENTS.md). Custom commands, mappings, settings, helper functions, and local plugins belong in [nvim/lua/customization](nvim/lua/customization/AGENTS.md). Startup and test harness files remain owned by [nvim](nvim/AGENTS.md).

# Connections

- [Neovim module](nvim/AGENTS.md): loads this Lua layer from `nvim/init.lua`.
- [Customization](nvim/lua/customization/AGENTS.md): receives the startup handoff for user-facing behavior.
- [Plugin layer](nvim/lua/plugins/AGENTS.md): registers third-party and development plugins before customization uses them.

# Placement

Use this layer for composition and Lua modules. Keep a new behavior in its owning child module, and avoid adding unrelated startup side effects to the top-level loader.
