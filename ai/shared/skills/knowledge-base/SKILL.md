---
name: knowledge-base
description: Search, manage, and extend a knowledge base using qmd CLI. Use when researching topics, building knowledge collections, organizing documents, adding new research materials, or querying indexed knowledge for project context and reference material.
---

# Knowledge Base Management & Research

## Overview

This skill enables agents to leverage qmd (Query Markdown) CLI for comprehensive knowledge base operations. Search and retrieve indexed knowledge, organize collections, add new research materials, and conduct structured research across a personal knowledge library.

## Core Capabilities

### 1. Searching & Querying
- Perform hybrid searches across indexed documents using qmd
- Execute keyword and semantic queries
- Filter by collection, tags, or metadata
- Retrieve relevant context for projects

### 2. Creating & Managing Collections
- Add new collections to the knowledge base
- Organize research materials by topic or domain
- Create structured collections with metadata
- Index documents for searchability

### 3. Research Workflows
- Conduct multi-document research
- Aggregate findings across collections
- Build context for new projects
- Reference existing knowledge systematically

### 4. Knowledge Organization
- Tag and categorize documents
- Update and maintain collections
- Migrate research between collections
- Clean and organize knowledge base

## Quick Start: Common Workflows

### Research a Topic
```bash
qmd search "topic keywords" --top 10 --pretty
```
**When to use**: You need background information on a topic before starting work.

### Add Research Materials
```bash
qmd add collection-name /path/to/documents --metadata key=value
```
**When to use**: You're building a new knowledge collection or documenting research.

### Create a New Collection
```bash
qmd create my-collection --description "Collection purpose and scope"
```
**When to use**: Starting a new knowledge domain or organizing related materials.

### Hybrid Search (Keywords + Semantic)
```bash
qmd search --query "question or topic" --collection collection-name
```
**When to use**: Looking for specific information within a focused collection.

## Working with qmd CLI

### Key Commands

| Command | Purpose | Use When |
|---------|---------|----------|
| `qmd search` | Query knowledge base | Looking for information or context |
| `qmd create` | Create new collection | Starting a new knowledge domain |
| `qmd add` | Add documents to collection | Building or extending a collection |
| `qmd list` | List collections or documents | Exploring available knowledge |
| `qmd info` | Show collection metadata | Understanding collection structure |
| `qmd update` | Modify collection metadata | Organizing or improving collections |
| `qmd remove` | Delete collection or document | Cleaning up or restructuring knowledge |

### Search Patterns

**Keyword Search** (exact terms):
```bash
qmd search "architecture patterns"
```

**Semantic Search** (concept-based):
```bash
qmd search "how do we structure large systems"
```

**Collection-Specific**:
```bash
qmd search "api design" --collection project-research
```

**With Filters**:
```bash
qmd search "pattern" --limit 20 --sort relevance
```

## Research Workflow Steps

### Step 1: Explore Existing Collections
```bash
qmd list
```
Check what knowledge is already available before conducting research.

### Step 2: Search for Relevant Information
```bash
qmd search "your research question" --top 10
```
Find relevant documents and context.

### Step 3: Review and Organize
Evaluate search results and determine if you need to add to the collection or refine your search.

### Step 4: Create Collection (if needed)
```bash
qmd create new-research-area \
  --description "Purpose and scope of this research collection"
```

### Step 5: Add Research Materials
```bash
qmd add new-research-area /path/to/documents --metadata source=research
```

### Step 6: Refine and Update
As you learn more, update collection metadata and add complementary materials.

## Best Practices

### Knowledge Base Organization
- Keep collections focused on a single domain or topic
- Use consistent naming: `kebab-case-for-collection-names`
- Add metadata to documents for better searchability
- Regularly review and clean up stale collections

### Effective Searching
- Start broad, then narrow your search with filters
- Use natural language for semantic searches
- Combine keyword + semantic searches for comprehensive results
- Review top results to validate search strategy

### Adding Materials
- Include source metadata when adding documents
- Use descriptive tags for cross-collection discovery
- Add context about why material is relevant
- Maintain consistent structure within collections

### Project-Specific Workflows
- Create a collection per major project
- Reference relevant shared knowledge collections
- Update project collections as you learn
- Use search to quickly onboard team members

## When to Use This Skill

✅ **Use when:**
- Researching a topic or technology
- Building knowledge collections
- Organizing research materials
- Retrieving context for projects
- Extending existing knowledge bases
- Conducting multi-document research

❌ **Don't use for:**
- Simple file reading (use Read tool directly)
- Code execution without research context
- One-off file operations

## Additional Resources

For detailed qmd CLI documentation and advanced patterns, see [references/qmd-reference.md](references/qmd-reference.md).

Example collection workflows available in [references/workflows.md](references/workflows.md).
