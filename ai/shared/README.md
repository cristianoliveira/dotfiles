# ai/shared

Shared resources consumed by the AI tools and stow links.

- `agents/`: used by Claude, OpenCode, and stowed at `~/.config/shared/agents`.
- `skills/`: shared skill definitions consumed by Claude and OpenCode.
- `commands/`: reusable command packs for OpenCode.
- `plugins/`: shared plugin assets.
- `todo.txt`: scratchpad for upcoming shared work.

Agents and skills are referenced via symlinks in `ai/claude` and `ai/opencode`, so keep paths stable when adding new assets.
