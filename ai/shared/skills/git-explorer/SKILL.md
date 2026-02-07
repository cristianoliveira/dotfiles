---
name: git-explorer
description: Use when the user mentions "searching Git/GitHub" to explore GitHub repositories, code, issues, and commits using advanced search capabilities.
---

# Git Explorer Skill

Use this skill when the user needs to search or explore GitHub content, including repositories, code, issues, pull requests, or commits. This skill leverages the `github-explorer` agent for advanced GitHub search using the GitHub CLI (`gh`) with sophisticated query construction.

## When to Use This Skill

- User explicitly mentions "search GitHub", "GitHub search", or similar phrases
- Need to find github repositories matching specific criteria (language, stars, topics, etc.)
- Need to search for code snippets across GitHub
- Need to explore issues, pull requests, or commits
- Need to perform advanced searches using GitHub's query language

## Key Capabilities

1. **Repository Search**: Find repositories by name, description, topics, language, stars, forks
2. **Code Search**: Search for code snippets across all public repositories
3. **Issue/PR Search**: Find issues and pull requests by state, labels, assignees, authors
4. **Commit Search**: Search commits by author, date, message content
5. **Advanced Filtering**: Use qualifiers, boolean operators, comparison operators, and ranges

## Recommended Approach

### 1. Invoke the GitHub Explorer Agent
For complex GitHub searches, delegate to the specialized `github-explorer` agent:

```bash
# Use the Task tool to launch the github-explorer agent
Task(description="Search GitHub", prompt="Search GitHub for repositories about machine learning with Python and >1000 stars", subagent_type="github-explorer")
```

The github-explorer agent has expertise in:
- GitHub CLI (`gh search`) with all subcommands
- Advanced query construction with qualifiers and operators
- Rate limit management and authentication
- JSON output processing and analysis

### 2. Direct GitHub CLI Commands
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

### 3. Query Construction Examples

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

## References

- GitHub Explorer agent: `/Users/cristianoliveira/.dotfiles/ai/shared/agents/github-explorer.md`
- GitHub advanced search research: `.tmp/docs/github-advanced-search.md`
- GitHub CLI documentation: `gh help search`
- GitHub search syntax: https://docs.github.com/en/search-github

## Notes

- For complex boolean logic (parentheses), use the github-explorer agent which has workarounds using the API endpoint
- The github-explorer agent is specifically designed to handle GitHub's advanced search capabilities and query limitations
- Always consider rate limits when performing multiple searches
