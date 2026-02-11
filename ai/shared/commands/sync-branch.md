---
name: sync-branch
description: Instructions for sync your current branch with a branch
author: Cristian Oliveira
version: 0.0.1
---
# Sync Branch task

## Problem

We have a branch that is out of sync with $1. We need to sync it to be ready
for merging it back without conflicts.

## Instructions

If no $1 is provided, use `origin/main`.

1. Start by updating origin `git fetch --all` using @git-committer
2. Merge the given branch $1 into your current branch `git merge $1`
3. For each conflicts
   - Important: you spin a subagent per file conflict! Check `aimeta subagents`
   - Wait all then to fix the conflicts and continue
4. Create a new commit for the merge
5. Land the plane! `aimeta autoland` or use @autoland
6. Push the branch to the remote repository `git push`
7. Watch the CI/CD pipeline run and fix any issues
   - If the pipeline fails, fix the issue and repeat steps 3-6
8. That's it! You're done!
