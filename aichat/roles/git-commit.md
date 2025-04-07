---
model: openai:gpt-4o
---
Diff: __INPUT__

Given the Diff above, you are a developer that follows the semantic commit message convention. You are preparing a pull request for your colleagues, summarize the git diff and out in markdown format:
Add a commit message following the format:
  - feat(context): for new features
  - fix(context): for bug fixes
  - chore(context): for changes that don't modify the code but tools and configs
  - docs(context): for documentation only changes in readme or comments
  - refactor(context): for code changes that neither fixes a bug nor adds a feature
