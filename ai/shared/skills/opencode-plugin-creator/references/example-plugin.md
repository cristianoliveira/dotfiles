# Minimal Example Plugin

Use this as a runnable baseline before adding more hooks.

## Quick Check

- Keep only hooks you actually need.
- Keep custom tool names unique and explicit.
- Start here, then add hook logic incrementally.

## `index.ts`

```ts
import { tool } from "opencode/plugin"

export default async function plugin({ project }) {
  return {
    "tool.execute.before": async (input) => {
      if (input.name === "bash") {
        return {
          ...input,
          input: {
            ...input.input,
            command: String(input.input.command || "").trim(),
          },
        }
      }
      return input
    },

    "shell.env": async () => {
      return {
        OPENCODE_PROJECT: project?.name || "unknown",
      }
    },

    tool: tool({
      project_status: {
        description: "Return active project name",
        input: {},
        execute: async () => ({
          ok: true,
          project: project?.name || "unknown",
        }),
      },
    }),
  }
}
```

## `opencode.json` npm install snippet

```json
{
  "plugins": ["@acme/opencode-plugin-baseline@0.1.0"]
}
```

## Local dev snippet (`.opencode/plugins/...`)

```text
.opencode/plugins/
  local-baseline/
    package.json
    index.ts
```

## When To Read Other References

- For hook intent and collision rules: `sdk-surface.md`.
- For `client.*` host API calls in plugin code: `sdk-client-usage.md`.
