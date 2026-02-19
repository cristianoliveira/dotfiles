---
name: jira-url-work-plan
description: |
  Use when the user wants to plan work based on a Jira issue.
  Triggers:
  - User share a Jira URL and ask for planning
  - Let's work on <JIRA_URL>
  - Plan the work for <JIRA_URL>
---

# Jira URL → Commit Plan (Markdown)

## When to use this skill (STRICT trigger)
Only use this skill when the user explicitly indicates they want to plan work for a Jira issue, using one of these patterns:
- "Let's start work on <JIRA_URL>"
- "Plan the work for <JIRA_URL>"
- "Break down <JIRA_URL> into commits"
- "Create an implementation plan for <JIRA_URL>"

If the user merely *shares* a Jira URL without one of the above intents, do NOT activate this skill.

## Inputs
- `JIRA_URL` (required): full URL to the Jira issue (copy/paste friendly)
- `OUTPUT_PATH` (optional): default `.tmp/plans/<ISSUE_KEY>.md`

## Output
A Markdown file containing:
- Ticket summary + Jira URL
- Problem statement (1–3 bullets)
- Assumptions / unknowns / questions
- Proposed solution outline (high level)
- Commit-sized deliverables (commit message + scope + acceptance criteria + tests)
- Non-goals / cut lines

## AVAILABLE TOOLS
- jira (ankitpokhrel/jira-cli) is installed and already authenticated/configured.
- scripts/fetch_issue.sh - fetches the issue content from Jira
- scripts/write_plan.py - Writes the commit plan to a Markdown file

## Procedure

### 1) Extract issue key from URL
- Parse the issue key from the URL (common forms include `.../browse/PROJ-123`, `selectedIssue=PROJ-123`, etc.).
- If extraction fails: ask the user for the issue key OR request a different Jira URL.

### 2) Fetch issue content
- Run: `scripts/fetch_issue.sh "<ISSUE_KEY>"`
- Capture stdout as `ISSUE_TEXT`.

### 3) Analyze and detect ambiguity
- Extract (best-effort): Summary, Description, Acceptance Criteria/DoD, Constraints, Dependencies, Risks.
- Identify missing/ambiguous parts. Examples:
  - unclear scope (“improve performance” but no target)
  - missing acceptance criteria
  - unspecified platforms/environments
  - unclear API/UI behavior or edge cases

### 4) Ask follow-up questions (MANDATORY to confirm your assumptions)
If any critical ambiguity exists, you MUST ask follow-up questions BEFORE producing the final commit plan.

Rules:
- Ask 3–8 questions max.
- Ask only what’s necessary to produce a correct plan.
- Prefer multiple-choice / option-style questions when possible.
- Do not invent answers. If user cannot answer, document as assumptions and flag risks.

After the user answers:
- Update assumptions and proceed.

### 5) Split into deliverables (commits)
- Create 3–12 commits max (unless the ticket is tiny).
- Each commit must be independently reviewable and have a clear validation step.
- Use Conventional Commits if repo uses it: `feat:`, `fix:`, `chore:`, `test:`, `docs:`, `refactor:`.

### 6) Write the plan
- Run: `scripts/write_plan.py --issue-key <ISSUE_KEY> --jira-url <JIRA_URL> --out <OUTPUT_PATH>`
- Pass `ISSUE_TEXT` via stdin.

### 7) Return to user
- Provide the output path and a short list of commit titles/messages.

## Guardrails
- Do not claim you ran commands if you did not.
- If user answers are missing, record them as assumptions + risks.
- Keep commits concrete (what/why/how to validate).
