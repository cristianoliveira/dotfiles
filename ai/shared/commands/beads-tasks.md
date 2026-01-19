---
description: Load beads workflow context and list current tasks
---

# Beads Tasks

Run `bd prime` to load the AI-optimized workflow context for beads issue tracking.

This outputs essential workflow context including:
- Current task priorities
- Workflow reminders
- Command reference (in CLI mode)

## Instructions

1. Run `bd prime` to get the current workflow context
2. Present the output to the user
3. Ask if they want to work on any specific task or need help with the beads workflow

## Landing the plane

- If the user wants you to land the plane, it means runs specified checks if all pass, at the end of the session ask the user if it considers the task done.
- If so, you can use `bd close` to close the current task.
