---
name: agent-creator
description: |
  Generate a new sub-agent configuration file from a user's description. Use when user says "let's create a new agent", "let's create a new subagent", "create a subagent for...", or asks to build/make a new agent/sub-agent.
---

# Agent Creator

Create sub-agent configuration files in Markdown format based on user descriptions.

## Triggers

- "Let's create a new agent"
- "Let's create a new subagent"
- "Create an agent for..."
- "Make a new sub-agent that..."

## Workflow

### 1. Gather Requirements

Ask the user:
- What is the agent's purpose?
- What tasks should it perform?
- What tools does it need? (Read, Write, Edit, Bash, Grep, Glob, WebFetch)

### 2. Fetch Documentation

Use WebFetch to get latest documentation:
- `https://docs.anthropic.com/en/docs/claude-code/sub-agents` - Sub-agent feature
- `https://docs.anthropic.com/en/docs/claude-code/settings#tools-available-to-claude` - Available tools
- `https://opencode.ai/docs/agents/` - OpenCode agents and documentation

### 3. Generate Agent Configuration

Create the agent file with:

**Frontmatter (YAML):**
- `name`: kebab-case identifier (e.g., `dependency-manager`, `api-tester`)
- `description`: Action-oriented delegation description starting with "Use when..." or "Specialist for..."
- `tools`: Minimal required tools (e.g., `Read, Grep, Glob` for reviewers; `Read, Edit, Bash` for debuggers)
- `model`: `haiku`, `sonnet`, or `opus` (default: `sonnet`)
- `color`: Optional hex color (e.g., `#ff00ff`)

**Body (Markdown):**
- `# Purpose`: Role definition
- `## Instructions`: Numbered steps for the agent to follow
- `**Best Practices:**`: Domain-specific guidelines
- `## Report / Response`: Output format specification

### 4. Write the File

Save to `ai/shared/agents/<name>.md` where `<name>` is the kebab-case identifier.

## Output Format

```md
---
name: <kebab-case-name>
description: <when-to-use-this-agent>
tools:
  <tool-name>: <true/false>
  <tool-name>: <true/false>
# If applicable, restrict tools to specific commands
permission:
  bash:
    "*": <allow/deny>
    "<command>": <allow/deny>
  read:
    "*": <allow/deny>
    "<file-pattern>": <allow/deny>
model: <model-name>
color: <hex-color>
---

# Purpose

You are a <role-definition>.

## Instructions

When invoked, follow these steps:
1. <step>
2. <step>
3. <step>

**Best Practices:**
- <practice>
- <practice>

## Report / Response

Provide your final response in a clear and organized manner.
```

## Tools

- **WebFetch**: Fetch latest Claude Code documentation
- **Write**: Create the agent configuration file
- **Question**: Gather user requirements if not provided

## Notes

- Keep descriptions action-oriented for automatic delegation
- Select minimal tools needed for the task
- Include numbered steps for reproducible workflows
