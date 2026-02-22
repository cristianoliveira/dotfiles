---
name: opencode-plugin-creator
description: Create and maintain OpenCode plugins with correct discovery, hook lifecycle, permissions, testing, and troubleshooting. Use when creating a new plugin, modifying existing plugin hooks, or debugging plugin failures.
---

# OpenCode Plugin Creator

Build, update, and debug OpenCode plugins with predictable structure and safe defaults.

## Available Tools

- `Read`: Inspect existing `SKILL.md`, plugin files, and config before changing behavior.
- `Glob`: Locate plugin directories and related files (for example `.opencode/plugins/**`).
- `Grep`: Find hook names, permissions, tool registrations, or error strings across files.
- `Edit`: Make focused updates to existing plugin or documentation files.
- `Write`: Create new plugin files or new docs when no file exists yet.
- `Bash`: Run validation commands, plugin smoke checks, and debug runs.

## Core Rules

1. Keep frontmatter minimal and valid.
2. Keep each plugin focused on one concern.
3. Return only hooks the plugin needs.
4. Use explicit permission behavior and prefer narrow patterns.
5. Use unique custom tool names unless override is intentional.
6. Pin published plugin versions in `opencode.json`.

## Workflow: Create a New Plugin

1. Choose scope: project plugin (`.opencode/plugins/`) or user plugin (`~/.config/opencode/plugins/`).
2. Create an async default export that receives plugin context.
3. Implement only required hooks (`event`, `tool.execute.before`, `tool.execute.after`, `permission.ask`, `shell.env`, `tool`).
4. Add minimal logging at startup and error boundaries.
5. Register custom tools with unique names.
6. Add or update plugin reference in `opencode.json` when using npm distribution.
7. Read `references/sdk-surface.md` first for context, hooks, and load behavior.
8. If the plugin calls host APIs through `client`, read `references/sdk-client-usage.md`.
9. If behavior depends on event timing, read `references/events-timeline.md`.

## Workflow: Modify or Refactor an Existing Plugin

1. Read current hooks and map behavior before editing.
2. Preserve existing plugin contract unless the task requires a breaking change.
3. Refactor one hook path at a time.
4. Keep permission logic explicit and audited after edits.
5. Re-check for tool-name collisions after renames or merges.
6. Update version pin or changelog note when behavior changes.
7. Use `references/example-plugin.md` to keep shape and naming consistent.

## Workflow: Troubleshoot Plugin Failures

1. Run OpenCode with debug logs:

```bash
opencode --print-logs --log-level DEBUG
```

2. Reproduce the failing flow and record which hook path executes.
3. Disable plugin(s) and rerun the same flow to isolate root cause.
4. Re-enable the target plugin and test incrementally after each fix.
5. Validate permissions, tool-name collisions, and plugin load path.
6. Compare with `references/example-plugin.md` to isolate shape or hook mistakes.
7. If failures involve host calls, validate `client` usage against `references/sdk-client-usage.md`.
8. If failures are event-order related, cross-check `references/events-timeline.md`.

## Reference Navigation (Read On Demand)

- Start with `references/sdk-surface.md` for a 60-second capability and hook check.
- Read `references/sdk-client-usage.md` only when plugin logic depends on `client.*` calls.
- Read `references/example-plugin.md` when creating or repairing plugin structure.
- Read `references/events-timeline.md` when you need event timing, ordering caveats, and payload confidence.

## Quick Check

- `references/sdk-surface.md`: context fields, hook families, collision rules, load paths, and common pitfalls.
- `references/sdk-client-usage.md`: minimal `client.*` call patterns used inside plugins.
- `references/events-timeline.md`: event names, timing cues, payload hints, and confidence labels.

## Examples

- `references/example-plugin.md`: minimal TypeScript plugin with `tool.execute.before`, `shell.env`, and a custom tool.

## Testing and Debugging

1. Trigger each changed hook path at least once.
2. Confirm expected output and absence of new permission regressions.
3. Confirm plugin loads from the intended location.
4. Re-run with plugin disabled to verify failure isolation.

## References

- `references/sdk-surface.md`
- `references/sdk-client-usage.md`
- `references/example-plugin.md`
- `references/events-timeline.md`
- https://opencode.ai/docs/plugins/
- https://opencode.ai/docs/config/
- https://opencode.ai/docs/permissions/
- https://opencode.ai/docs/cli/
- https://opencode.ai/docs/troubleshooting/
