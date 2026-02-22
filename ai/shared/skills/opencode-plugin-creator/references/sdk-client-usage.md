# SDK Client Usage In Plugins

Use this only when plugin logic needs host API calls through `client`.

## Fast Pattern

```ts
export default async function plugin({ client }) {
  return {
    event: async () => {
      const result = await client.project.current()
      if (result.error) return
      // use result.data safely
    },
  }
}
```

## Quick Mapping

| Need | Typical Call |
| --- | --- |
| Current project info | `client.project.current()` |
| Session metadata | `client.session.get({ path: { id } })` |
| Session messages | `client.session.messages({ path: { id } })` |
| Config snapshot | `client.config.get()` |

## Guardrails

- Always check `result.error` before using `result.data`.
- Keep client calls bounded to the active flow; avoid wide scans in hooks.
- Prefer deterministic calls in hooks that run often (`event`, `tool.execute.*`).
- Use official API details when needed: https://opencode.ai/docs/sdk/
