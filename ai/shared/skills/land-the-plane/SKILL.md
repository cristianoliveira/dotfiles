---
name: land-the-plane
description: Pre-merge CI validation - run all CI checks locally before committing. Use when user says "land the plane", "let's wrap up", "final checks", "ready to merge?", "run CI locally", or wants to verify code passes all automated checks before creating a PR or merging. Does NOT commit changes - only validates.
---

# Land the Plane

Final pre-merge validation: discover and run all CI checks locally to ensure code is ready to merge.

## Trigger Phrases

- "land the plane"
- "final checks"
- "make ready to commit"

## Workflow

### BEFORE STARTING (IMPORTANT)

1) **DO NOT CD TO ANOTHER DIRECTORY**

Start by checking if commands are already discovered:
```bash
$HOME/.dotfiles/ai/bin/aimeta autoland --list
```

IF no commands are found, follow instructions in `instructions/COMMANDS_DISCOVERY.md`.

2) **YOU DO NOT LAND THE PLANE, USE AUTOLAND INSTEAD**

Use the `autoland` sub-agent to land the plane, is safer and faster.

### 1. Run Commands in Parallel via autoland Subagent

**IMPORTANT**: Delegate check execution to the `autoland` agent for parallel processing.

Using the commands listed in the previous step, use the **Task** tool to launch the autoland agent with the discovered commands:
```
Task(
  subagent_type="autoland",
  description="Run CI checks in parallel",
  prompt="Run these CI validation commands in parallel using gob (cached: true/false):
    - npm run lint
    - npm run typecheck
    - npm test
    - npm run build
  Report results as they complete. Return a summary table with pass/fail status for each."
)
```

The autoland agent will:
1. Start all checks simultaneously with `gob add`
2. Collect results as they finish with `gob await-any`
3. Return a summary of all results

This is significantly faster than sequential execution

### 2. Report Summary

After all checks complete, provide a clear summary:

```
## Pre-merge Validation Results

| Check        | Status | Notes           |
|--------------|--------|-----------------|
| Lint         | PASS   |                 |
| Types        | PASS   |                 |
| Tests        | FAIL   | 2 failing tests |
| Build        | PASS   |                 |

Ready to merge: NO - fix failing tests first
```

### 3. Offer to Fix (if failures)

If any checks failed, use the **Question** tool to ask the user:

> "Some checks failed. Would you like me to try fixing these issues?"

Options:
- "Yes, fix the issues" - Attempt to fix and re-run failed checks
- "No, I'll handle it" - End the workflow, user fixes manually

If user chooses yes, fix the issues and re-run ONLY the previously failed checks to verify the fix. Repeat until all checks pass or user declines.

### 4. Handoff to git-committer (after checks pass)

When all checks pass (or the user explicitly wants to proceed), delegate to the `git-committer` agent to stage and create commits:
- Provide the `git-committer` agent with context (tracked/untracked files, desired scope) and let it follow its branch/atomic-commit flow.
- Use the Task tool to call git-committer (example):
```
Task(
  subagent_type="git-committer",
  description="Prepare commits after autoland checks passed",
  prompt="Use git-committer workflow: confirm status, stage approved files, create atomic commits on a temp branch, write messages to .tmp/git/<task>-commit.txt. Do not push."
)
```
- If the user prefers multiple commits (atomic per logical change), instruct git-committer accordingly.
- If a develop/integration branch is used, allow git-committer to keep the environment on that branch when done (per its instructions).
