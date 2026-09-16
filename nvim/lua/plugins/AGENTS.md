# Purpose

`nvim/lua/plugins/` owns repository-local plugin specifications that are kept separate from the main plugin list, including debugging, AI assistance, and review integrations.

# Boundaries

Third-party plugin registration shared directly by the main loader belongs in [nvim/lua](../AGENTS.md). User-facing commands and mappings that consume plugins belong in [nvim/lua/customization](../customization/AGENTS.md).

# Connections

- [Lua composition layer](../AGENTS.md): loads these specifications through the main plugin setup.
- [Customization](../customization/AGENTS.md): consumes the plugin capabilities through commands, mappings, and settings.

# Placement

Add a file here when a plugin specification has enough configuration or lifecycle concerns to deserve a named module. Keep one-off plugin options in the main list when extracting them would not create a useful ownership boundary.
