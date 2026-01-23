# ai/shared

Shared resources consumed by the AI tools and stow links.

## Directories

- `agents/`: Agent prompts used by Claude, OpenCode, and stowed at `~/.config/shared/agents`.
- `skills/`: Shared skill definitions consumed by Claude and OpenCode.
- `commands/`: Reusable command packs for OpenCode.
- `plugins/`: Shared plugin assets.
- `scripts/`: Helper scripts used by agents and skills.
- `todo.txt`: Scratchpad for upcoming shared work.

## Agents (13)

| Agent | Description |
|-------|-------------|
| `autoland` | Like in aviation, autoland helps an agent to land the plane safely. Runs CI checks in parallel. |
| `confluence-researcher` | Use when you need to search Confluence documents using Confluence CLI to find answers to research questions. |
| `git-committer` | Use this agent to prepare commits after CI validations. |
| `github-explorer` | Use when you need to explore GitHub repos using advanced search. |
| `janitor` | Use when you need to review and clean up after other agents' work. |
| `librarian` | Use when you need to index, search, and organize research documents using qmd CLI for advanced hybrid search and knowledge retrieval. |
| `orchestrator` | Orchestrator agent that delegates tasks to appropriate subagents based on request type. |
| `plan-splitter` | Splits big tasks/epics into small deliverables using beads and bd CLI |
| `research-assistant` | Use an assistant to investigate subtopics concurrently (web and local codebases). |
| `researcher` | A research-focused agent that organizes research topics, delegates to research-assistant subagents, and synthesizes findings into .tmp/docs/<research-name>.md |
| `task-worker` | Use this agent for simple implementation focued on a single task. |
| `web-qa` | Web quality assurance - check if URLs/pages are working, validate page content, verify UI elements |
| `web-summarizer` | Use this agent to extract and summarize web content from URLs. (surf cli) |

## Skills (11)

| Skill | Description |
|-------|-------------|
| `agent-creator` | Generate a new sub-agent configuration file from a user's description. Use when user says "let's create a new agent", "let's create a new subagent", "create a subagent for...", or asks to build/make a new agent/sub-agent. |
| `ci-workflow` | Follow a Continuous Improvement (CI) development workflow where work, test, check, give feedback, complete, and repeat. |
| `db-explorer` | Connect to PostgreSQL, MySQL, or SQLite databases to explore schema structure, table relationships, and generate ERD diagrams. Use when the user asks to explore a database, document schema, or understand table relationships. |
| `git-explorer` | Use when the user mentions "searching Git" or "GitHub" to explore GitHub repositories, code, issues, and commits using advanced search capabilities. |
| `gh-address-comments` | Help address review/issue comments on the open GitHub PR for the current branch using gh CLI; verify gh auth first and prompt the user to authenticate if not logged in. |
| `jira-task-creator` | Create Jira tasks from user requirements with structured templates, acceptance criteria, and linking to epics/parent issues. Use when user wants to create a Jira ticket, track work items, or document tasks with clear acceptance criteria. Handles project selection, priority, labels, components, assignee, and linking to existing issues. |
| `jira-to-plan` | Given a Jira issue URL, fetch the issue via jira-cli, analyze it, ask clarifying questions if needed, split into commit-sized deliverables, and write a Markdown implementation plan. |
| `land-the-plane` | Pre-merge CI validation - run all CI checks locally before committing. Use when user says "land the plane", "let's wrap up", "final checks", "ready to merge?", "run CI locally", or wants to verify code passes all automated checks before creating a PR or merging. Does NOT commit changes - only validates. |
| `logcli-logs` | Query and analyze logs from Grafana Loki using logcli. Use when the user mentions Loki, Grafana logs, logcli, or LogQL. Triggers on phrases like "query loki", "loki logs", "grafana logs", "use logcli", "LogQL query", or when explicitly asked to search logs using Loki/Grafana infrastructure. |
| `look-at-the-logs` | Search through specific provided logs to find specific information. |
| `skill-creator` | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. |

## Commands

- `beads-tasks.md` - Load beads workflow context and list current tasks
- `ci-workflow.md` - Follow a CI development workflow where work, test, check, give feedback, complete, and repeat.
- `librarian-init.md` - Initialize qmd collections for a project to enable advanced hybrid search of markdown documents using the librarian agent.
- `prime-leader.md` - You are a leader agent, you do not work on tasks, but rather plan and delegate to sub-agents.
- `tdd-workflow.md` - Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests.

## Plugins

- `agentmux-opencode.js` - AgentMux integration for OpenCode

## Scripts

- `git-committer/git-commit-context.sh` - Gathers context for commit messages

---

Agents and skills are referenced via symlinks in `ai/claude` and `ai/opencode`, so keep paths stable when adding new assets.
