---
name: self-improvement
description: |
    Capture agent corrections and mistakes for continuous learning across the agent ecosystem.
    Use when: agent discovers its own mistake, user corrects agent, edge case was missed, or repeatable pattern emerges.
    Triggers:
      - "I made a mistake"
      - "I should have done X instead"
      - "Learned something about Z"
      - "Pattern I missed"
      - User says "let's capture this feedback"
author: Agent Learning Framework
version: 0.1.0
---

# Self-Improvement Skill

Capture corrections, mistakes, and learnings to improve agent performance across the ecosystem.

## Overview

Agents learn best from:
1. **Mistakes we discover** — understanding why we went wrong
2. **Corrections from users** — direct feedback on better approaches
3. **Edge cases we miss** — patterns that trip us up repeatedly
4. **Domain-specific patterns** — rules specific to a project or task type

This skill provides a structured workflow to capture these learnings so they become part of the agent ecosystem's collective knowledge.

## When to Use This Skill

Use **self-improvement** when you encounter any of these situations:

- ✅ You realize you took the wrong approach mid-task
- ✅ A user corrects you or points out a better way
- ✅ You handle an edge case but realize you should have seen it sooner
- ✅ You notice a pattern: "I always mess up X with Y"
- ✅ You discover a project-specific rule or convention
- ✅ You find a tool usage mistake or incorrect assumption
- ✅ A task fails and you understand what you should have done differently

## Core Workflow

### 1. Quick Capture: `aimeta self-improvement add`

Immediately capture feedback with key details:

```bash
aimeta self-improvement add \
  --agent "file-operations" \
  --category "missing-validation" \
  --severity "medium" \
  --mistake "Edited file without reading it first" \
  --correction "Always read file before editing to understand structure" \
  --tags "file-ops,validation,safety" \
  --context "Tried to use edit tool on unknown file structure"
```

**Key fields:**
- `agent`: The agent type that made the mistake (e.g., "file-operations", "git-workflow", "api-integration")
- `category`: Error type (e.g., "missing-validation", "assumption-error", "sequence-mistake", "safety-issue")
- `severity`: `low` | `medium` | `high` (impact on correctness/safety)
- `mistake`: What went wrong (1-2 sentences)
- `correction`: How to do it better (specific action, not vague)
- `tags`: Searchable labels for grouping learnings
- `context`: Why this mattered in this situation

### 2. Batch Review: `aimeta self-improvement review-session`

At the end of a session or before a major task:

```bash
aimeta self-improvement review-session
```

This:
- Lists all feedback captured in this session
- Shows patterns (repeated mistakes, categories)
- Suggests which ones to export or archive
- Allows you to merge similar items

### 3. Export & Share: `aimeta self-improvement export`

Share learnings with the agent ecosystem:

```bash
aimeta self-improvement export --format json --output learnings.json
aimeta self-improvement export --format markdown --skill-suggestion
```

Exports can be:
- **JSON** for integration with training data
- **Markdown** for documentation and handoff
- **Skill suggestion** to generate new skill trigger patterns

## Practical Examples

### Example 1: File Operations Mistake

```
Agent: file-operations
Mistake: I used the edit tool on a file I hadn't read yet
Correction: ALWAYS read file first using read tool (with limit if large)
Category: missing-validation
Severity: high
Tags: file-ops, safety, sequence

Why: Avoided reading first because I thought I could infer structure.
This led to incorrect edits and caused the user to waste time fixing it.
```

**→ Skill Impact:** Could trigger a new validator skill: "always-read-first"

### Example 2: Git Workflow Mistake

```
Agent: git-operations
Mistake: Tried to push without checking if local branch diverged from remote
Correction: ALWAYS run `git status` and `git fetch` before push operations
Category: sequence-mistake
Severity: high
Tags: git, safety, branch-tracking

Why: Caused a conflict and needed manual intervention.
Should verify branch is clean and tracking before any push.
```

### Example 3: API Integration Pattern

```
Agent: api-integration
Mistake: Assumed API endpoint would return cached data when it didn't
Correction: Never assume caching behavior; explicitly check response headers
            and timestamps if caching matters
Category: assumption-error
Severity: medium
Tags: api, assumptions, caching

Why: Spent cycles debugging why data seemed stale.
API documentation mentioned possible caching but I skipped it.
```

### Example 4: Tool Usage Edge Case

```
Agent: bash-executor
Mistake: Used `find` command with glob patterns instead of proper regex
Correction: Always use proper regex syntax for find; test with simple
            patterns first to verify behavior
Category: tool-misuse
Severity: low
Tags: bash, find, patterns

Why: Command worked but was fragile. Proper understanding of find syntax
would have been faster.
```

## Command Reference

### `aimeta self-improvement add`
**When to use:** Immediately when you discover a mistake or receive correction

**Inputs:**
- `--agent`: Agent type (required)
- `--mistake`: What went wrong (required)
- `--correction`: How to do it better (required)
- `--category`: Error classification (required)
- `--severity`: low | medium | high (required)
- `--tags`: Comma-separated labels (optional)
- `--context`: Situation context (optional)
- `--interactive`: Guided input mode (optional)

### `aimeta self-improvement review-session`
**When to use:** End of task, before major work, or weekly review

**Outputs:**
- Session summary with mistake counts by category
- Pattern detection (repeated mistakes)
- Suggestions for skills to create
- Export recommendations

### `aimeta self-improvement export`
**When to use:** Ready to share learnings, creating pull request, documenting patterns

**Formats:**
- `--format json`: For training systems
- `--format markdown`: For documentation
- `--format skill-suggestion`: Generate new skill draft
- `--output <file>`: Save to specific file
- `--since <date>`: Export from date onward
- `--category <cat>`: Filter by category

## Integration Points

### For Orchestrator Agents
When you spot an agent making a mistake, suggest:
```
"Would you like to use self-improvement skill to capture this?
It helps the ecosystem learn."
```

### For New Skill Creators
Review exported learnings to:
- Identify patterns that warrant new skills
- Find validation rules to add to existing skills
- Understand common edge cases

### For Periodic Reviews
- Monthly: Review all learnings, merge duplicates
- Quarterly: Create new skills from high-severity patterns
- As-needed: Export and share with other agents

## Bundled Resources

- **[feedback-patterns.md](references/feedback-patterns.md)** — Common mistake patterns by agent/tool type
- **[integration-guide.md](references/integration-guide.md)** — How to integrate with agent workflows
- **[best-practices.md](references/best-practices.md)** — Detailed best practices for effective feedback

## Best Practices (Quick Summary)

1. **Be specific:** "Forgot to check if file exists" not "Messed up file handling"
2. **Make corrections actionable:** Include exact steps or rules
3. **Add discovery context:** Why did you realize the mistake?
4. **Use appropriate severity:** Consider impact, not just effort to fix
5. **Tag consistently:** Use tags from `feedback-patterns.md` for better grouping
6. **Review weekly:** Batch similar learnings together

See **[best-practices.md](references/best-practices.md)** for detailed guidance.

## Next Steps

1. **Read the bundled guides** for patterns and integration details
2. **Set up periodic reviews** using `review-session` command
3. **Share learnings** by running `export` and checking for patterns
4. **Contribute improvements** by creating new skills from high-impact learnings
