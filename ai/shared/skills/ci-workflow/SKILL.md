---
name: ci-workflow
description: Follow a Continuous Improvement (CI) development workflow where work, test, check, give feedback, complete, and repeat.
---
# CI Workflow (Continuous Improvement)

## When to use this skill (STRICT trigger)
Only use this skill when the user explicitly indicates they want work in a CI Workflow, using one of these patterns:
- "Let's start in a CI workflow"
- "Work in a CI workflow"
- "Work with a continous IMPROVEMENT workflow"

##  Beads Tasks (BD)

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
    - IMPORTANT: request feedback from the agent after he finishes about their instructions, like was it clear, did it work, etc.
- Delegate to a tester to verify the task done
- Delegate to a reviewer to provide feedback
- Land the plane!
- COMMIT YOUR WORK
- Using previous feedback, add to beads if needed follow up tasks
- Take the next task from `bd`
- Repeat until all tasks are completed
  - After 3 tasks asks for users feedback!
