# Purpose

`nvim/` owns the Neovim development environment: startup, plugin registration, Lua customization, snippet library, and the local test harness.

# Boundaries

Startup wires the plugin layer and customization layer. Plugin declarations belong in [nvim/lua/plugins](lua/plugins/AGENTS.md); user-facing editor behavior belongs in [nvim/lua/customization](lua/customization/AGENTS.md). The Nix dev shell that supplies Neovim tooling belongs in [nix](../nix/AGENTS.md), while the headless load check belongs in [bin](../bin/AGENTS.md).

# Connections

- [Nix system state](../nix/AGENTS.md): provides the development shell and packages used by the editor checks.
- [Helpers](../bin/AGENTS.md): runs the headless configuration load check.
- [Lua plugin layer](lua/plugins/AGENTS.md): supplies third-party plugin registration consumed during startup.
- [Customization layer](lua/customization/AGENTS.md): supplies commands, mappings, settings, helper functions, and local plugins loaded during startup.
- [Snippet library](mysnippets/AGENTS.md): provides language and framework snippet templates used by the editor.

# Placement

Start navigation at `nvim/init.lua`, then follow the two startup branches. Add editor behavior to the narrowest customization area that owns it; add a plugin declaration to the plugin layer rather than embedding it in a command or mapping.
