# Knowledge Base Workflows

This document outlines common workflows for managing and researching with the knowledge base.

## Table of Contents

1. [Research Workflows](#research-workflows)
2. [Collection Management Workflows](#collection-management-workflows)
3. [Knowledge Organization Workflows](#knowledge-organization-workflows)
4. [Project-Specific Workflows](#project-specific-workflows)

---

## Research Workflows

### Quick Topic Research

**Scenario**: You need to quickly gather information on a topic before starting work.

**Steps:**
1. Search the knowledge base
2. Review top results
3. Gather context for the task

```bash
# Step 1: Search for the topic
qmd search "kubernetes deployment" --top 10 --pretty

# Review results and determine if you need more specific info
# Step 2: If needed, search within specific collection
qmd search "helm charts" --collection devops-research --pretty
```

**Output**: Compiled context to inform your work on the topic.

---

### Deep Topic Research

**Scenario**: You need comprehensive understanding of a complex topic.

**Steps:**
1. Create a research collection
2. Add relevant materials
3. Conduct targeted searches
4. Aggregate findings

```bash
# Step 1: Create a focused collection for this research
qmd create microservices-research \
  --description "Deep research into microservices patterns and best practices"

# Step 2: Add relevant documentation
qmd add microservices-research ./docs --recursive --metadata source=team
qmd add microservices-research ./papers --recursive --metadata source=research

# Step 3: Conduct targeted searches
qmd search "service discovery" --collection microservices-research --top 20
qmd search "api gateway patterns" --collection microservices-research --top 20
qmd search "circuit breaker pattern" --collection microservices-research --top 20

# Step 4: Review and organize findings
qmd list --collection microservices-research --detailed
```

**Output**: Organized research collection with tagged materials for future reference.

---

### Project-Based Research

**Scenario**: You're starting a new project and need to gather relevant context.

**Steps:**
1. Identify existing relevant collections
2. Search for related materials
3. Create project-specific collection
4. Add and organize project materials

```bash
# Step 1: List existing collections to find relevant ones
qmd list --detailed

# Step 2: Search across relevant collections
qmd search "api design" --collection api-standards
qmd search "testing strategies" --collection testing-best-practices

# Step 3: Create project-specific collection
qmd create project-name-research \
  --description "Research and reference materials for Project Name"

# Step 4: Add project-specific materials
qmd add project-name-research ./project-docs --recursive
qmd add project-name-research ./research --recursive --metadata type=research
```

**Output**: Centralized project knowledge base ready for reference during development.

---

## Collection Management Workflows

### Creating a New Knowledge Domain

**Scenario**: You want to establish a new area of knowledge organization.

**Steps:**
1. Plan the collection structure
2. Create the main collection
3. Define metadata and tags
4. Add initial materials

```bash
# Step 1: Create collection with clear description
qmd create cloud-architecture \
  --description "Cloud infrastructure patterns, services, and best practices" \
  --metadata domain=infrastructure source=internal

# Step 2: Add initial materials
qmd add cloud-architecture ./guides --recursive \
  --metadata type=guide \
  --tags architecture,cloud

qmd add cloud-architecture ./case-studies --recursive \
  --metadata type=case-study \
  --tags architecture,lessons-learned

# Step 3: Verify structure
qmd info cloud-architecture
qmd list --collection cloud-architecture --detailed
```

**Output**: Well-organized collection ready for team knowledge sharing.

---

### Bulk Adding Materials to a Collection

**Scenario**: You have a directory of documents to add to a collection.

**Steps:**
1. Organize source materials
2. Add with appropriate metadata
3. Tag for discoverability
4. Verify addition

```bash
# Add all markdown files with consistent metadata
qmd add research-collection ./documents --recursive \
  --pattern "*.md" \
  --metadata source=documentation type=reference \
  --tags important

# Add from specific subdirectories with different tags
qmd add research-collection ./patterns --recursive \
  --metadata type=pattern \
  --tags design-pattern

qmd add research-collection ./tutorials --recursive \
  --metadata type=tutorial \
  --tags learning,guide

# Verify all materials were added
qmd list --collection research-collection --detailed
```

**Output**: All materials indexed and discoverable within the collection.

---

### Organizing Existing Collections

**Scenario**: Your collection has grown and needs better organization.

**Steps:**
1. List and review current materials
2. Update descriptions and metadata
3. Add/update tags for consistency
4. Clean up duplicates or outdated materials

```bash
# Review current collection structure
qmd list --collection api-docs --detailed

# Update collection metadata for clarity
qmd update api-docs \
  --description "API endpoints, design patterns, and integration guides" \
  --metadata version=2.0 last-reviewed=2025

# Update document tags for consistency
qmd update api-docs --document doc-123 --tags api,rest,documentation

# Remove outdated or duplicate materials
qmd remove api-docs doc-456  # Remove deprecated API doc
```

**Output**: Well-organized collection with consistent metadata and tags.

---

## Knowledge Organization Workflows

### Tagging Strategy for Discovery

**Scenario**: You want to implement a tagging system for cross-collection discovery.

**Recommended Tags:**
- **Domain**: `backend`, `frontend`, `devops`, `database`, `security`
- **Type**: `guide`, `tutorial`, `reference`, `case-study`, `pattern`
- **Status**: `complete`, `in-progress`, `review`, `deprecated`
- **Priority**: `critical`, `important`, `reference`, `interesting`

```bash
# When adding materials, use consistent tags
qmd add architecture-patterns ./pattern.md \
  --tags architecture,design-pattern,important

# When updating, apply consistent tagging
qmd update architecture-patterns --document doc-123 \
  --tags architecture,design-pattern,review

# Search by tags across collections
qmd search "authentication" --tags security,critical
```

**Output**: Consistent tagging enables cross-collection searches and discovery.

---

### Metadata Strategy

**Recommended Metadata Keys:**
- `source`: Where the material came from (e.g., `team`, `external`, `research`)
- `type`: Kind of material (e.g., `guide`, `specification`, `example`)
- `status`: Current state (e.g., `current`, `archived`, `review`)
- `reviewed-by`: Who last reviewed this material
- `last-updated`: When material was last updated

```bash
# Add with comprehensive metadata
qmd add project-docs ./file.md \
  --metadata \
    source=team \
    type=architecture \
    status=current \
    reviewed-by=john-doe \
    last-updated=2025-02

# Update metadata as materials evolve
qmd update project-docs --document doc-123 \
  --metadata status=archived reviewed-by=jane-doe
```

**Output**: Rich metadata enables better filtering and discovery.

---

## Project-Specific Workflows

### Starting a New Project

**Complete workflow for new project setup:**

```bash
# 1. Create project collection
qmd create new-project-research \
  --description "Research and reference for New Project" \
  --metadata project=new-project start-date=2025-02

# 2. Add team standards and best practices
qmd add new-project-research ./team-standards --recursive \
  --metadata source=internal type=standard \
  --tags important

# 3. Add architecture and design docs
qmd add new-project-research ./architecture --recursive \
  --metadata type=architecture \
  --tags architecture

# 4. Add relevant patterns and examples
qmd add new-project-research ./patterns --recursive \
  --metadata type=pattern source=team \
  --tags design-pattern

# 5. Verify setup
qmd info new-project-research
qmd list --collection new-project-research --detailed

# 6. Use for reference during development
qmd search "authentication patterns" --collection new-project-research
```

**Output**: Ready-to-use project knowledge base.

---

### Maintaining a Learning Collection

**Workflow for continuously growing your knowledge base:**

```bash
# 1. Create learning collection
qmd create learning-log \
  --description "Continuous learning and skill development"

# 2. Add learning materials as you encounter them
qmd add learning-log ./tutorial.md --metadata type=tutorial source=course

# 3. Tag by subject area
qmd add learning-log ./guide.md --tags kubernetes,devops

# 4. Regularly review and organize
qmd list --collection learning-log --detailed

# 5. Search to reinforce learning
qmd search "topic" --collection learning-log
```

**Output**: Continuously growing personal knowledge base.

---

### Archiving Old Collections

**When a collection is no longer actively used:**

```bash
# 1. Option A: Update metadata to mark as archived
qmd update old-collection --description "ARCHIVED: Previous project research"

# 2. Option B: Create archive collection
qmd create archive --description "Archived collections and old materials"

# 3. Option C: Remove if truly obsolete
qmd remove obsolete-collection
```

---

## Troubleshooting Common Workflows

### Collection Too Large
If searches are returning too many results:
- Add more specific tags
- Use `--collection` flag to narrow scope
- Break into multiple smaller collections

### Finding Lost Materials
If you can't find something:
```bash
# Search more broadly
qmd search "topic" --top 50

# List all materials in collection
qmd list --collection name --detailed

# Search by metadata
qmd search "*" --metadata status=current
```

### Merging Collections
If you want to combine collections:
```bash
# 1. Export all documents from source collection
qmd list --collection source-collection --format json

# 2. Add documents to target collection
qmd add target-collection ./exported-docs --recursive

# 3. Remove source collection when complete
qmd remove source-collection
```

---

## Best Practices Summary

- **Be consistent**: Use the same tags, metadata keys, and naming conventions
- **Plan for growth**: Structure collections assuming they'll become large
- **Document sources**: Always note where materials came from
- **Regular maintenance**: Review and clean up collections periodically
- **Search often**: Use searches to keep knowledge fresh and discoverable
