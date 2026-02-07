---
name: gh-ci-debugging
description: |
    Given a GitHub URL related to GitHub Actions, debug CI failures;
    'let's debug CI failure at <URL>`, 'fix CI failure at <URL>`
---

# PR CI Debug Handler

Guide to find the open PR for the current branch and debug its CI failures with gh CLI. Run all `gh` commands with elevated network access.

Prereq: ensure `gh` is authenticated (for example, run `gh auth login` once), then run `gh auth status` with escalated permissions (include workflow/repo scopes) so `gh` commands succeed.

## 1) Inspect CI failures
- Check the logs for the current CI run -- `gh run view <run-id>`

## 2) Ask the user for clarification
- Number all the CI failures and provide a short summary of what would be required to apply a fix for it
- Ask the user which numbered failures should be addressed

## 3) If user chooses failures
- Apply fixes for the selected failures

## 4) Commit the changes
- Commit the changes to the PR

## 5) Re-run the CI
- Re-run the CI for the PR -- `gh run rerun <run-id>`
- Watch the CI run and wait for it to complete -- `gh run watch <run-id>`
- If the CI fails, Goto step 1

Notes:
- If gh hits auth/rate issues mid-run, prompt the user to re-authenticate with `gh auth login`, then retry.
