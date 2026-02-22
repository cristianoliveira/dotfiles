# OpenCode SDK Surface Quick Check

Use this page to confirm what plugin code can access.

## Read This First

- Need a fast map of plugin input and hooks? Read this file.
- Need concrete `client.*` calls? Read `sdk-client-usage.md`.
- Need a working skeleton? Read `example-plugin.md`.

## Plugin Function Signature and Context

| Item | Purpose |
| --- | --- |
| `project` | Active project context and metadata. |
| `directory` | Current working directory for this run. |
| `worktree` | Git worktree path used by the runtime. |
| `client` | Runtime client for host interactions. |
| `$` | Shell helper for running commands. |

Example shape:

```ts
export default async function plugin({ project, directory, worktree, client, $ }) {
  return {}
}
```

## 30-Second Hook Check

| Hook | Use It For | Common Mistake |
| --- | --- | --- |
| `event` | Observe runtime lifecycle events. | Treating it as a mutation hook. |
| `tool.execute.before` | Normalize or validate tool input. | Mutating unrelated tool calls. |
| `tool.execute.after` | Post-process tool output and metadata. | Returning incompatible output shape. |
| `permission.ask` | Allow/deny/adjust permission decisions. | Defaulting to broad allow behavior. |
| `shell.env` | Inject env vars for shell execution. | Leaking large or sensitive env sets. |
| `tool` | Expose custom tools from plugin code. | Using non-unique tool names. |

## Core Hook Families

- `event`: observe lifecycle and runtime events.
- `tool.execute.before`: inspect or adjust tool input before execution.
- `tool.execute.after`: inspect output after execution.
- `permission.ask`: approve, deny, or modify permission behavior.
- `shell.env`: inject or modify environment variables for shell tools.
- `tool`: expose custom tools via the plugin.

## Custom Tool Exposure (`tool()` helper)

- Return a `tool()` hook from the plugin export.
- Register unique names to avoid accidental overrides.
- Keep input schema narrow and response shape predictable.

## Collision and Load Notes

- Name collisions are resolved by plugin load order; later-loaded definitions can override earlier ones.
- Keep custom tool names namespaced (for example `acme_status`) unless replacement is intentional.
- Config is typically loaded from project `opencode.json`, then user config under `~/.config/opencode/`.
- Local project plugins under `.opencode/plugins/` are useful for development and fast iteration.

## Quick Decisions

| If You Need | Read Next |
| --- | --- |
| Minimal plugin shape | `example-plugin.md` |
| Host API usage from plugin code | `sdk-client-usage.md` |
| Official behavior details | Source links below |

## Short Source Links

- https://opencode.ai/docs/plugins/
- https://opencode.ai/docs/config/
- https://opencode.ai/docs/permissions/
- https://opencode.ai/docs/cli/
