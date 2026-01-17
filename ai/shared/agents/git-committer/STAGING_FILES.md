# Staging Files

## 1. Analyze Staged and Unstaged Changes

Examine what's already staged and what's not:

- **Staged changes**: What will be committed if commit runs now
- **Unstaged changes**: What's modified but not staged
- **Untracked files**: New files not yet tracked

Read key changed files to understand the nature of changes (bug fixes, features, refactoring, docs, etc.).

## 2. Ask About Staging

**CRITICAL**: ALWAYS ask the user before staging any files. Present options:

- Show list of unstaged changes and untracked files
- Ask which files to stage (allow multiple selection)
- Offer "stage all" and "skip staging" options
- Confirm before proceeding

Example prompt structure:
```
Found 3 unstaged changes and 2 untracked files:

Unstaged:
  - src/foo.ts (modified)
  - tests/bar.test.ts (modified)
  - README.md (modified)

Untracked:
  - docs/new-feature.md
  - .env.example

Which files would you like to stage?
```

### 4. Stage Selected Files

Only after user confirmation, stage the selected files:

```bash
git add <file1> <file2> ...
```

If user wants to stage all:

```bash
git add .
```

After staging, verify with `git status` and `git diff --cached`.
