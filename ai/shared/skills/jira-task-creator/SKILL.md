---
name: jira-task-creator
description: Create Jira tasks from user requirements with structured templates, acceptance criteria, and linking to epics/parent issues. Use when user wants to create a Jira ticket, track work items, or document tasks with clear acceptance criteria. Handles project selection, priority, labels, components, assignee, and linking to existing issues.
---

# Jira Task Creator

## Overview

This skill helps create well-structured Jira tasks from user descriptions. It guides through gathering requirements, formatting them into a standardized template with acceptance criteria, and optionally creating the issue via jira CLI or providing the command for manual execution.

## Triggers

Use this skill when the user asks to:

- (Let's) Create a Jira ticket, issue, or task
- Make a Jira issue for a bug, feature, or task
- Create a ticket in Jira with the standard template

## Workflow

### 1. Gather Task Information
- Ask for project key (if not provided)
- Ask for issue summary/title
- Ask for detailed description of the problem/requirement
- Ask for acceptance criteria (bullet points)
- Ask about screenshots (if applicable)
- Ask about relevant links (if applicable)
- Make sure to check for other Jira tickets for more context

### 2. Gather Additional Fields
- Ask for priority (High, Medium, Low)
- Ask for labels (comma-separated)
- Ask for components (comma-separated)
- Ask for assignee (username)
- Ask about linking to parent issue, epic, or related issues
- Ask if screenshots section should be included

### 3. Create Template
Format the collected information into the structured template:
```markdown
# Description

{Problem description}

## Acceptance criteria
- {Acceptance criteria 1}
- {Acceptance criteria 2}
- {Acceptance criteria 3}
- {etc}

## Screenshots (if applicable)

{Screenshot}
{Notes about screenshot}

## Relevant links (if applicable)

{Links}
```

### 4. Execute or Prepare
- Ask user preference: auto-create with jira CLI or prepare command
- If auto-create: run `jira issue create` with appropriate flags
- If prepare command: display the full `jira issue create` command with all flags
- If user wants to review/edit first: save template to file for editing

## Jira CLI Commands

The jira CLI (`jira`) must be installed and configured. Key flags:

- `-p, --project string`: Project key (required)
- `-t, --type string`: Issue type (default: Task)
- `-s, --summary string`: Issue summary/title
- `-b, --body string`: Issue description (template content)
- `-y, --priority string`: Priority (High, Medium, Low)
- `-l, --label stringArray`: Labels (repeat for multiple)
- `-C, --component stringArray`: Components (repeat for multiple)
- `-a, --assignee string`: Assignee username
- `-P, --parent string`: Parent issue key for linking
- `--template string`: Path to file for description (alternative to -b)

## Tools and Usage

### Available Tools
- **Question**: Gather user preferences and requirements
- **Bash**: Execute jira CLI commands, check configuration
- **Write/Edit**: Create template files if needed
- **Read**: Read existing templates or configuration

### When to Use Which Tool
- Use **Question** for interactive gathering of task details
- Use **Bash** for checking jira configuration (`jira me`, `jira project list`) and creating issues
- Use **Write** to create temporary template files if user wants to edit before creation

## Examples

**Example user request**: "I need to create a Jira ticket for fixing the login page bug where the submit button is unresponsive on mobile."

**Skill response**:
1. Ask for project key (e.g., WEBAPP)
2. Ask for summary: "Login page submit button unresponsive on mobile"
3. Ask for detailed description and acceptance criteria
4. Gather priority (High), labels (bug,mobile), components (frontend)
5. Ask about linking to any existing issues
6. Format into template
7. Ask if auto-create or prepare command
8. Execute or display command

## References

- [Jira Template](references/template.md): Detailed template structure and placeholders
- [Jira CLI Guide](references/jira_cli.md): Complete jira CLI command reference and examples

## Notes

- Always verify jira CLI is authenticated (`jira me`)
- List available projects with `jira project list` if user unsure
- For parent/epic linking, ask for issue key (e.g., WEBAPP-123)
- Screenshots section should only be included if user provides screenshots or notes
- BEFORE CREATING ASK FOR CONFIRMATION
