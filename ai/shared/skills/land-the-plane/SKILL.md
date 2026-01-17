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

### 1. Discover CI Configuration

Search for CI/CD definitions in order of priority:

```
.github/workflows/*.yml     # GitHub Actions (primary)
.gitlab-ci.yml              # GitLab CI
.circleci/config.yml        # CircleCI
Jenkinsfile                 # Jenkins
.travis.yml                 # Travis CI
azure-pipelines.yml         # Azure DevOps
```
Git hooks:
```
.githooks/pre-commit        # Git pre-commit hook
.githooks/pre-push          # Git pre-push hook
```

### 2. Discover Task Runners

Also check for task definitions that CI might invoke:

```
Makefile / GNUmakefile      # Make targets
package.json                # npm/yarn scripts
justfile                    # Just command runner
Taskfile.yml                # Task runner
pyproject.toml              # Python (pytest, ruff, mypy)
Cargo.toml                  # Rust (cargo test, cargo clippy)
mix.exs                     # Elixir
build.gradle / pom.xml      # Java/Kotlin
```

### 3. Extract Commands from CI

Parse workflow files to identify:

- **Linting**: eslint, ruff, rubocop, golangci-lint, clippy
- **Type checking**: tsc, mypy, pyright
- **Formatting**: prettier, black, gofmt, rustfmt
- **Tests**: jest, pytest, go test, cargo test, mix test
- **Build**: npm run build, cargo build, go build, make build

Look for `run:` steps in GitHub Actions. Extract the actual shell commands.

### 4. Run Commands in Parallel via plane-lander Subagent

**IMPORTANT**: Delegate check execution to the `plane-lander` agent for parallel processing.

Use the **Task** tool to launch the plane-lander agent with the discovered commands:

```
Task(
  subagent_type="plane-lander",
  description="Run CI checks in parallel",
  prompt="Run these CI validation commands in parallel using gob:
    - npm run lint
    - npm run typecheck
    - npm test
    - npm run build
  Report results as they complete. Return a summary table with pass/fail status for each."
)
```

The plane-lander agent will:
1. Start all checks simultaneously with `gob add`
2. Collect results as they finish with `gob await-any`
3. Return a summary of all results

This is significantly faster than sequential execution

### 5. Report Summary

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

### 6. Offer to Fix (if failures)

If any checks failed, use the **Question** tool to ask the user:

> "Some checks failed. Would you like me to try fixing these issues?"

Options:
- "Yes, fix the issues" - Attempt to fix and re-run failed checks
- "No, I'll handle it" - End the workflow, user fixes manually

If user chooses yes, fix the issues and re-run ONLY the previously failed checks to verify the fix. Repeat until all checks pass or user declines.

### 7. Generate Commit Message (if all pass)

Once all checks pass, prepare a commit message for the user:

1. Run `git diff --staged` and `git diff` to see all changes
2. Run `git log -5 --oneline` to understand the repo's commit style
3. Analyze the changes and conversation context to understand what was done
4. Write a commit message following Conventional Commits format:
   - `type(scope): summary` (e.g., `feat(auth): add OAuth2 login flow`)
   - Include a body if changes are complex (the "why", not the "what")
5. Save to `.tmp/git/<task>-commit.txt` where `<task>` is a short slug (e.g., `add-oauth-login`)
6. Present the commit message to the user and let them know the file location

Example output:
```
All checks passed! Ready to commit.

Suggested commit message (saved to .tmp/git/add-oauth-login-commit.txt):

feat(auth): add OAuth2 login flow

Implement Google and GitHub OAuth providers with token refresh
handling. Includes new middleware for session validation.

Would you like me to commit with this message?
```

Use **Question** tool to ask if user wants to commit now or just keep the message for later.

## Important Notes

- **Do NOT commit** - this skill only validates, user decides when to commit
- **Do NOT push** - no remote operations
- **Run exact CI commands** - match what CI does, don't improvise
- **Skip deployment steps** - only run validation/test steps
- **Skip secrets-dependent steps** - skip steps requiring CI secrets/tokens
- **Use plane-lander agent** - always delegate check execution for parallel processing

## Tools

- **Task**: Launch plane-lander agent for parallel check execution (primary tool for step 4)
- **Glob**: Find CI config files (`.github/workflows/*.yml`, `Makefile`, etc.)
- **Read**: Parse workflow YAML and task runner configs
- **Bash**: git diff/log for commit message generation
- **Write**: Save commit message to `.tmp/git/<task>-commit.txt`
- **TodoWrite**: Track workflow progress
- **Question**: Ask user if they want to fix failures or commit
