---
name: librarian-init
description: Initialize qmd collections for a project to enable advanced hybrid search of markdown documents using the librarian agent.
author: Cristian Oliveira
version: 0.1.0
---

# Librarian Initialization Command

Use this command to set up qmd collections for a project, enabling advanced hybrid search (BM25 keyword + vector semantic + LLM reranking) of markdown documents through the librarian agent.

## Overview

qmd is a local search engine for markdown files that provides three search modes:
- **Keyword search** (`qmd search`): Fast BM25 matching for exact terms
- **Vector search** (`qmd vsearch`): Semantic understanding using embeddings
- **Hybrid search** (`qmd query`): Combines both + LLM reranking for best results

## Prerequisites

1. **qmd installation**: Verify qmd is installed with `which qmd` or `qmd --version`
2. **Project structure**: Have your markdown files organized in a directory structure
3. **Disk space**: ~3GB for initial model downloads during first embedding

## Installation via Nix

If you're using this dotfiles repository with Nix, qmd is already available via the overlay:

```bash
# qmd is installed system-wide when using nix-darwin
which qmd
```

The overlay is defined in `nix/overlays/nightly-pkgs.nix` and provides the latest version from GitHub.

## MCP Server Integration

qmd includes an MCP (Model Context Protocol) server that can be used with AI tools like OpenCode:

```json
{
  "qmd": {
    "type": "local",
    "command": ["qmd", "mcp"]
  }
}
```

The MCP server provides programmatic access to qmd's search capabilities from within AI agent contexts.

## Initialization Steps

### 1. Check Current Status
```bash
qmd status
qmd collection list
```

### 2. Create Collections Based on Project Type

**For documentation-heavy projects:**
```bash
# Single collection for entire project
qmd collection add docs ./docs --glob "**/*.md" --context "Project documentation and API references"

# Or separate by content type
qmd collection add api-docs ./docs/api --glob "*.md" --context "API documentation and endpoints"
qmd collection add guides ./docs/guides --glob "*.md" --context "User guides and tutorials"
```

**For research projects:**
```bash
qmd collection add research ./research --glob "*.md" --context "Research notes and findings"
qmd collection add papers ./papers --glob "*.md" --context "Academic papers and summaries"
```

**For general note-taking:**
```bash
qmd collection add notes ./notes --glob "**/*.md" --context "Personal notes and meeting summaries"
```

### 3. Generate Embeddings
```bash
# Initial embedding (downloads models on first run)
qmd embed

# Check embedding progress
qmd status
```

### 4. Verify Setup
```bash
# List all collections
qmd collection list

# Test search
qmd search "introduction" -c docs --limit 5
qmd vsearch "architecture overview" -c docs --limit 3
```

## Recommended Collection Strategies

### Single Project Setup
```bash
# All project markdown in one collection
qmd collection add project ./ --glob "**/*.md" --context "All project documentation and notes"
```

### Multi-Project Setup
```bash
# Separate collections per project
qmd collection add project-a ./projects/a --glob "**/*.md" --context "Project A documentation"
qmd collection add project-b ./projects/b --glob "**/*.md" --context "Project B documentation"
```

### Content-Type Based Setup
```bash
# Separate by document type
qmd collection add docs ./docs --glob "*.md" --context "Technical documentation"
qmd collection add notes ./notes --glob "*.md" --context "Meeting notes and ideas"
qmd collection add specs ./specs --glob "*.md" --context "Specifications and requirements"
```

## Integration with Librarian Agent

After initialization, you can use the librarian agent to:
- Search collections with natural language queries
- Retrieve documents for analysis
- Generate structured reports from search results
- Manage collection lifecycle

**Example agent invocation:**
```
"Search my project docs for authentication patterns"
"Update the index with new documentation files"
"Create a summary report of architecture discussions"
```

## Maintenance Commands

### Update Index
```bash
# When adding new files
qmd update

# Force re-embedding
qmd embed --force
```

### Monitor Status
```bash
# Check index health
qmd status

# List all indexed files
qmd ls <collection-name>

# Clean up stale data
qmd cleanup
```

### Remove Collections
```bash
# List collections
qmd collection list

# Remove a collection
qmd collection remove <collection-name>
```

## Troubleshooting

**qmd not found**: Ensure it's installed via Nix or system package manager
**No models downloaded**: First `qmd embed` will download ~3GB of models automatically
**Slow embedding**: Initial embedding is CPU-intensive; runs in background
**Search returns nothing**: Check glob patterns match your file structure

## Next Steps

1. **Test search**: Try different search modes with sample queries
2. **Integrate with workflow**: Use librarian agent for research/documentation tasks
3. **Regular updates**: Run `qmd update` when adding significant new content
4. **Expand collections**: Add new collections as project scope grows

---

**Note**: This command guides the setup process. For actual search operations, use the librarian agent or qmd CLI directly.
