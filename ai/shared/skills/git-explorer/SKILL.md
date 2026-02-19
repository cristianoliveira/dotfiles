---
name: github-explorer
description: |
    Use when the user mentions
    - "... search on Git/GitHub"
    - "... on GitHub"
    - "... on CI/CD".
---

# Getting Started

 - Start by checking if GH CLI is setup: `gh auth status`
 - Then understand GH cappabilities with `gh help`

## Skill Usage

### Direct GitHub CLI Commands
For simple searches, you can use `gh` commands directly:

```bash
# Search repositories
gh search repos "machine learning" --language=python --stars=">1000" --limit=10 --json

# Search code
gh search code "def train_model" --language=python --repo=org/repo --json

# Search issues
gh search issues "bug" --state=open --label=bug --json

# Search commits
gh search commits "fix memory leak" --author=username --json
```

### Query Construction Examples

**Basic repository search:**
```bash
gh search repos "neural network" --language=python --stars=">500" --json | jq -r '.[] | "\(.nameWithOwner): \(.description)"'
```

**Advanced search with multiple qualifiers:**
```bash
gh search repos "topic:deep-learning language:python stars:>1000 forks:>100" --json
```

**Code search with path filtering:**
```bash
gh search code "import torch" --language=python --path="src/" --json
```

## Qualifiers Reference

Common GitHub search qualifiers:
- `repo:owner/name` - Specific repository
- `language:python` - Programming language
- `stars:>1000` - Star count
- `forks:>100` - Fork count
- `topic:machine-learning` - Repository topics
- `path:src/` - File path
- `filename:*.py` - File name pattern
- `is:public` / `is:private` - Repository visibility
- `created:>2023-01-01` - Creation date
- `pushed:>2024-01-01` - Last push date

## Best Practices

1. **Use JSON output**: Always add `--json` flag for machine-readable results
2. **Limit results**: Use `--limit` to control output size (default 30, max 100)
3. **Authenticate for higher limits**: Run `gh auth login` for higher rate limits (30 vs 10 requests/minute)
4. **Combine flag-based and raw qualifiers**: Some qualifiers work better as flags, others in raw query
5. **Test with small limits first**: Use `--limit=2` to verify query syntax before full execution
6. **Process results with jq**: Filter and format JSON output for readability

## Common Use Cases

### Finding Popular Repositories
```bash
gh search repos "machine learning" --language=python --stars=">10000" --json | jq -r '.[] | "\(.nameWithOwner) (\(.stargazerCount) stars): \(.description)"'
```

### Searching for Code Patterns
```bash
gh search code "from transformers import" --language=python --json | jq -r '.[] | "\(.repository.nameWithOwner): \(.path)"'
```

### Exploring Issues by Label
```bash
gh search issues "good first issue" --state=open --label="good first issue" --json | jq -r '.[] | "\(.repository.nameWithOwner)#\(.number): \(.title)"'
```

## Important

 - Write down your findings in `.tmp/researches/github-<task>.md`
