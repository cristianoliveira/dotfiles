# ai/shared

Shared resources consumed by the AI tools and stow links.

## Directories

- `agents/`: Agent prompts used by Claude, OpenCode, and stowed at `~/.config/shared/agents`.
- `skills/`: Shared skill definitions consumed by Claude and OpenCode.
- `commands/`: Reusable command packs for OpenCode.
- `plugins/`: Shared plugin assets.
- `scripts/`: Helper scripts used by agents and skills.
- `todo.txt`: Scratchpad for upcoming shared work.

## Agents (8)

| Agent | Description |
|-------|-------------|
| `autoland` | Runs CI checks in parallel using gob for pre-merge validation |
| `git-committer` | Prepares commits after CI validation passes |
| `orchestrator` | Primary leader agent that delegates tasks to subagents |
| `plan-splitter` | Splits big tasks/epics into small deliverables using beads/bd CLI |
| `research-assistant` | Investigates subtopics concurrently (web and local codebases) |
| `researcher` | Coordinates research, delegates to assistants, synthesizes findings |
| `task-worker` | Implements small, well-defined deliverables autonomously |
| `web-summarizer` | Extracts and summarizes web content from URLs |

## Skills (9)

| Skill | Description |
|-------|-------------|
| `agent-creator` | Generates new sub-agent configuration files |
| `db-explorer` | Explores database schemas and generates ERD diagrams |
| `gh-address-comments` | Addresses PR review comments via gh CLI |
| `jira-task-creator` | Creates Jira tasks with templates and acceptance criteria |
| `jira-to-plan` | Converts Jira issues into commit-sized implementation plans |
| `land-the-plane` | Pre-merge CI validation - runs all checks locally |
| `logcli-logs` | Queries Grafana Loki logs using logcli |
| `look-at-the-logs` | Searches through specific provided logs |
| `skill-creator` | Guide for creating new skills |

## Commands

- `beads-tasks.md` - Beads task management commands
- `prime-leader.md` - Prime leader command pack

## Plugins

- `agentmux-opencode.js` - AgentMux integration for OpenCode

## Scripts

- `git-committer/git-commit-context.sh` - Gathers context for commit messages

---

Agents and skills are referenced via symlinks in `ai/claude` and `ai/opencode`, so keep paths stable when adding new assets.
