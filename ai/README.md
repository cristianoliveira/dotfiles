# AI Tools Configuration

Unified structure for all AI tool configurations with shared resources.

## Structure

```
ai/
├── shared/           # Shared agents & skills across all tools
│   ├── agents/      # Reusable agent prompts
│   └── skills/      # Reusable skills (look-at-the-logs, gh-address-comments)
├── aichat/          # AIChat (config, macros, roles, scripts)
├── claude/          # Claude Code (settings, mcp, plugins, skills→shared)
├── codex/           # OpenAI Codex CLI (config.toml, skills→shared)
├── crush/           # Crush (crush.json, commands)
└── opencode/        # OpenCode (opencode.json, agent→shared, skills→shared)
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
| Crush | `~/.config/crush/` | `ai/crush/` |
| OpenCode | `~/.config/opencode/{opencode.json,agent,skills}` | `ai/opencode/*` & `ai/shared/*` |

## MCP Servers (Aligned Across All Tools)

All tools use the same three MCP servers:
- **nixos**: NixOS documentation (`uvx mcp-nixos`)
- **filesystem**: Log access (`npx @modelcontextprotocol/server-filesystem`)
- **playwright**: Browser automation (`npx @playwright/mcp`)

Configured in:
- `ai/aichat/mcp.json`
- `ai/claude/mcp.json`
- `ai/codex/config.toml`
- `ai/opencode/opencode.json`

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
