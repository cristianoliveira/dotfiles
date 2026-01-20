# AI Tools Configuration

Unified structure for all AI tool configurations with shared resources.

## Structure

```
ai/
├── shared/           # Shared agents & skills across all tools
│   ├── agents/       # 8 reusable agent prompts (orchestrator, task-worker, etc.)
│   ├── skills/       # 9 reusable skills (db-explorer, land-the-plane, etc.)
│   ├── commands/     # Shared commands (beads-tasks, prime-leader)
│   └── plugins/      # Shared plugins (agentmux-opencode.js)
├── aichat/           # AIChat (config.yaml, mcp.json, roles/, macros/, scripts/)
├── claude/           # Claude Code (settings.json, mcp.json, plugins/, agents→shared, skills→shared)
├── codex/            # OpenAI Codex CLI (config.toml, skills→shared)
├── opencode/         # OpenCode (opencode.json, agent→shared, skills→shared, commands→shared)
└── .tmp/             # Temporary files (docs/, researches/, git/)
```

## Installation

```bash
# Install all AI configs
stow -d stow -t ~ ai

# Refresh after changes
stow -d stow -t ~ --restow ai
```

## Symlink Map

| Tool | Location | Points To |
|------|----------|-----------|
| Claude | `~/.claude/{settings.json,mcp.json,plugins,agents,skills}` | `ai/claude/*` & `ai/shared/*` |
| Codex | `~/.codex/{config.toml,skills}` | `ai/codex/*` & `ai/shared/*` |
| AIChat | `~/.config/aichat/` | `ai/aichat/` |
| OpenCode | `~/.config/opencode/{opencode.json,agent,skills,commands,plugins}` | `ai/opencode/*` & `ai/shared/*` |

## Stow Layout

Stowing `ai` creates these links:
- `~/.claude/{agents,settings.json,mcp.json,plugins,skills}` → `stow/ai/.claude/*` → `ai/claude/*` (agents/skills are already symlinked to `ai/shared`).
- `~/.codex/{config.toml,skills}` → `stow/ai/.codex/*` → `ai/codex/*` (skills are already symlinked to `ai/shared`).
- `~/.config/aichat` → `stow/ai/.config/aichat` → `ai/aichat`.
- `~/.config/opencode` → `stow/ai/.config/opencode` → `ai/opencode`.
- `~/.config/shared/agents` → `stow/ai/.config/shared/agents` → `ai/shared/agents` (via the `ai/claude/agents` link).
- On macOS, `stow/ai/after_install.sh` also links `~/Library/Application Support/aichat` to `~/.config/aichat` when missing.

## MCP Servers (Aligned Across All Tools)

All tools use the same three core MCP servers:
- **nixos**: NixOS documentation (`uvx mcp-nixos`)
- **filesystem**: Log access (`npx @modelcontextprotocol/server-filesystem`)
- **playwright**: Browser automation (`npx @playwright/mcp --headless --browser=chromium`)

Claude Code also includes:
- **gob**: Additional MCP server (`gob mcp`)

Configured in:
- `ai/aichat/mcp.json`
- `ai/claude/mcp.json`
- `ai/codex/config.toml` (via `[mcp_servers]` sections)
- `ai/opencode/opencode.json` (via `mcp` object)

## Adding New Resources

**New shared skill:**
```bash
mkdir -p ai/shared/skills/my-skill
echo "# My Skill" > ai/shared/skills/my-skill/SKILL.md
# Auto-available to all tools via symlinks
```

**New AI tool:**
```bash
mkdir ai/newtool
# Add config files
ln -s ../shared/skills ai/newtool/skills  # Optional
cd stow/ai/.config && ln -s ../../../ai/newtool newtool
stow -d stow -t ~ --restow ai
```

## Philosophy

- **Single source**: One file, one location
- **Share by default**: Common resources in `shared/`
- **Tool autonomy**: Tool-specific settings stay separate
- **Version controlled**: Everything tracked in git
- **Stow managed**: Automated symlinks
