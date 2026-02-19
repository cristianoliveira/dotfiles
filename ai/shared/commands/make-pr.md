---
name: make-pr
description: This command instruct a agent to prepare a PR.
author: Cristian Oliveira
version: 0.0.1
---
# Make PR

Follow this instructions to prepare and create a PR.
Please use the appropriate sub-agents to execute each step.

## Workflow

1. Make sure your landed the plane! use @autoland
2. Stage all changes and commit your changes with a relevant message @git-committer
3. Push your changes to the remote repository `git push`
4. Create a PR `gh pr create`
5. Ensure the CI is passing `gh run list` @github-worker
  - If the CI is failing, investigate and fix the issue, before continuing.
6. Check any comment in CI before continuing.

## Handling failures

If the tests are failing, Please investigate and fix the issue, before continuing.
