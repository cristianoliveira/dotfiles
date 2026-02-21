# qmd CLI Reference Guide

## Command Structure

```bash
qmd [command] [options] [arguments]
```

## Commands Reference

### Search Operations

#### qmd search
Search the knowledge base using keyword or semantic queries.

```bash
qmd search <query> [options]
```

**Options:**
- `--query <string>` - Search query (required)
- `--collection <name>` - Limit search to specific collection
- `--top <number>` - Return top N results (default: 5)
- `--limit <number>` - Maximum results to return
- `--sort <relevance|date|name>` - Sort results (default: relevance)
- `--pretty` - Format output for readability
- `--fields <field1,field2>` - Select specific fields to display

**Examples:**
```bash
# Basic search
qmd search "docker architecture"

# Semantic search with limit
qmd search "how to scale applications" --top 20

# Collection-specific search
qmd search "api endpoints" --collection api-docs

# Formatted output
qmd search "authentication" --collection security --pretty --top 10
```

### Collection Management

#### qmd create
Create a new collection in the knowledge base.

```bash
qmd create <collection-name> [options]
```

**Options:**
- `--description <text>` - Collection description
- `--metadata <key=value>` - Add metadata pairs
- `--tags <tag1,tag2>` - Add tags for discovery

**Examples:**
```bash
# Basic collection
qmd create project-research

# With description
qmd create api-standards --description "API design patterns and standards"

# With metadata and tags
qmd create kubernetes-notes \
  --description "Kubernetes deployment patterns" \
  --metadata source=internal --tags devops,container
```

#### qmd add
Add documents or files to a collection.

```bash
qmd add <collection-name> <path> [options]
```

**Options:**
- `--metadata <key=value>` - Document metadata
- `--tags <tag1,tag2>` - Document tags
- `--recursive` - Process directories recursively
- `--pattern <glob>` - Match specific file patterns
- `--source <name>` - Mark document source

**Examples:**
```bash
# Add single document
qmd add project-research ./research.md

# Add directory recursively
qmd add project-research ./docs --recursive

# Add with metadata
qmd add project-research ./architecture.md --metadata type=design --source=team

# Add multiple markdown files
qmd add api-docs ./docs --recursive --pattern "*.md" --tags api
```

#### qmd list
List collections or documents in the knowledge base.

```bash
qmd list [options]
```

**Options:**
- `--collection <name>` - List documents in collection
- `--detailed` - Show metadata and details
- `--format <json|table|plain>` - Output format (default: table)

**Examples:**
```bash
# List all collections
qmd list

# List documents in collection
qmd list --collection project-research --detailed

# JSON output for parsing
qmd list --collection api-docs --format json
```

#### qmd info
Show detailed information about a collection or document.

```bash
qmd info <collection-name> [document-id]
```

**Examples:**
```bash
# Collection info
qmd info project-research

# Document info
qmd info project-research doc-123
```

#### qmd update
Update collection or document metadata.

```bash
qmd update <collection-name> [options]
```

**Options:**
- `--description <text>` - Update description
- `--metadata <key=value>` - Update metadata
- `--tags <tag1,tag2>` - Update tags
- `--document <id>` - Update specific document

**Examples:**
```bash
# Update collection description
qmd update project-research --description "Updated description"

# Update document tags
qmd update project-research --document doc-123 --tags important,reference
```

#### qmd remove
Delete a collection or document.

```bash
qmd remove <collection-name> [document-id]
```

**Examples:**
```bash
# Remove entire collection
qmd remove old-research

# Remove specific document
qmd remove project-research doc-123
```

## Search Query Syntax

### Keyword Searches
```bash
qmd search "exact phrase in quotes"
qmd search multiple keywords without quotes
qmd search keyword1 AND keyword2
qmd search keyword1 OR keyword2
qmd search -keyword (exclude keyword)
```

### Semantic Searches
```bash
qmd search "How should we architect this?"
qmd search "What are best practices for scaling?"
qmd search "Explain the pattern used in this system"
```

### Advanced Filters
```bash
qmd search "query" --collection name
qmd search "query" --metadata source=internal
qmd search "query" --tags important
```

## Output Formats

### Table Format (default)
```
ID          Title               Collection          Score
doc-1       Architecture Guide  project-research    0.95
doc-2       API Design          api-docs            0.87
```

### Pretty Format
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Result 1: Architecture Guide
Collection: project-research
Relevance Score: 0.95
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### JSON Format
```json
{
  "results": [
    {
      "id": "doc-1",
      "title": "Architecture Guide",
      "collection": "project-research",
      "score": 0.95
    }
  ]
}
```

## Common Patterns

### Bulk Adding Documents
```bash
# Add all markdown files in directory
qmd add project-docs ./docs --recursive --pattern "*.md"

# Add with consistent metadata
qmd add research ./papers --recursive --metadata type=research source=academic
```

### Searching Multiple Collections
```bash
# Search in specific collection
qmd search "pattern" --collection api-docs

# Search across all (no --collection flag)
qmd search "pattern"
```

### Organizing by Tags
```bash
# Create tagged documents for easy discovery
qmd add project-research ./file.md --tags architecture,design,review

# Find all tagged items
qmd search "architecture" --tags design
```

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Collection not found` | Collection doesn't exist | Use `qmd list` to see available collections |
| `Document not found` | Invalid document ID | Check collection with `qmd list --collection name` |
| `Permission denied` | Insufficient permissions | Check file/directory permissions |
| `Invalid syntax` | Query formatting issue | Check query syntax matches examples above |

### Troubleshooting

```bash
# Verify qmd is installed and working
qmd --version

# Check available collections
qmd list

# Test search with simple query
qmd search "test" --top 5 --pretty

# View detailed error information
qmd search "query" --debug
```
