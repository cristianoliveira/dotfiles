# Purpose

`nvim/mysnippets/` owns the repository's UltiSnips snippet library: language-specific and framework-specific text expansion templates used inside Neovim.

# Boundaries

Only snippet definitions and their grouping belong here. Plugin registration that loads these snippets belongs in [nvim/lua/plugins](../lua/plugins/AGENTS.md); commands or mappings that interact with snippets belong in [nvim/lua/customization](../lua/customization/AGENTS.md).

# Connections

- [Neovim module](../AGENTS.md): exposes this directory to the snippet plugin during startup.
- [Plugin specifications](../lua/plugins/AGENTS.md): registers the snippet engine and its search paths.
- [Customization layer](../lua/customization/AGENTS.md): provides user-facing commands and mappings that expand or search snippets.

# Placement

Add a snippet file for a language or framework here when the expansion is reusable editor content. Keep editor behavior, key bindings, and plugin setup in their owning modules.
