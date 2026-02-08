---
name: make-pr
description: This command instruct a agent to prepare a PR.
author: Cristian Oliveira
version: 0.0.1
---
# Make PR

Follow this instructions to prepare and create a PR.

## Workflow

1. Make sure your landed the plane! `aimeta autoland`
2. Stage all changes
3. Commit your changes with a relevant message
4. Push your changes to the remote repository `git push`
5. Create a PR `gh pr create`
6. Close the task in beads `bd close <task-id>` - Update with feedback and commit hash
7. Take the next task from `bd`

## Handling failures

If the tests are failing, Please investigate and fix the issue, before continuing.
