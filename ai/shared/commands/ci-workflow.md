---
name: ci-workflow
description: Follow a CI development workflow where work, test, check, give feedback, complete, and repeat.
author: Cristian Oliveira
version: 0.0.1
---

# Beads Tasks (BD)

Beads (bd) is our task management tool for managing and tracking work.
Run `bd prime` to load the AI-optimized workflow context for beads issue tracking.

This outputs essential workflow context including:
- Current task priorities
- Workflow reminders
- Command reference (in CLI mode)

## Workflow
- Start by taking the next task from `bd`
- Analyze the task and determine what has to be done
- Delegate to the appropriate sub-agent to perform the task
    - Instruct the agent to Create a branch for the task `git checkout -b <task-name> && git reset --hard develop`
    - IMPORTANT: request feedback from the agent after he finishes about their instructions, like was it clear, did it work, etc.
- Delegate to a tester to verify if the task done
- Delegate to a reviewer to provide feedback -- @janitor
- Land the plane! -- @autoland
- COMMIT YOUR WORK -- @git-committer
- Using previous feedback, add to beads if needed follow up tasks
- Merge your change to `develop` branch
- Take the next task from `bd`
- Repeat until all tasks are completed
  - After 3 tasks asks for users feedback!

## Definition of Done
  - All tasks are completed
  - **Important** Code is modular and clean, if nor file tasks as Tech Debt!
  - Tests and linter are passing
  - There are no files to be committed (DO NOT DELETE FILES)
