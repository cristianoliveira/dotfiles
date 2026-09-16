# Purpose

`nvim/lua/customization/plugins/` owns small local plugin integrations that register editor commands or behavior for this configuration, such as argument-list and grep helpers.

# Boundaries

Third-party plugin specifications belong in [nvim/lua/plugins](../../plugins/AGENTS.md). Shared helper code belongs in [utils](../utils/AGENTS.md); key bindings and named commands remain in [mappings](../mappings/AGENTS.md) and [commands](../commands/AGENTS.md).

# Connections

- [Customization](../AGENTS.md): loads these local integrations during startup.
- [Plugin specifications](../../plugins/AGENTS.md): provides the external plugin registrations consumed by these integrations.
- [Utilities](../utils/AGENTS.md): supplies reusable support where local integrations need it.

# Placement

Add a module here when repository-specific glue around a plugin owns its own commands or state. Keep generic plugin setup in the plugin layer and generic helpers in utilities.
