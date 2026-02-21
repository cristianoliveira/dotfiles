#!/bin/bash
# Batch add documents to knowledge base collection
# Usage: ./batch_add.sh <collection-name> <source-directory> [tags] [metadata]

set -e

COLLECTION="${1:-}"
SOURCE_DIR="${2:-}"
TAGS="${3:-}"
METADATA="${4:-}"

if [ -z "$COLLECTION" ] || [ -z "$SOURCE_DIR" ]; then
	echo "Usage: batch_add.sh <collection-name> <source-directory> [tags] [metadata]"
	echo ""
	echo "Examples:"
	echo "  ./batch_add.sh project-research ./docs"
	echo "  ./batch_add.sh api-docs ./api-guides \"api,documentation\" \"source=team\""
	echo "  ./batch_add.sh research ./papers \"research,academic\" \"source=papers type=research\""
	exit 1
fi

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
	echo "❌ Source directory not found: $SOURCE_DIR"
	exit 1
fi

echo "📚 Collection: $COLLECTION"
echo "📁 Source: $SOURCE_DIR"
echo ""

# Build qmd command
CMD="qmd add \"$COLLECTION\" \"$SOURCE_DIR\" --recursive"

if [ -n "$TAGS" ]; then
	CMD="$CMD --tags $TAGS"
	echo "🏷️  Tags: $TAGS"
fi

if [ -n "$METADATA" ]; then
	CMD="$CMD --metadata $METADATA"
	echo "📝 Metadata: $METADATA"
fi

echo ""
echo "Running: $CMD"
echo ""

# Execute the command
eval "$CMD"

echo ""
echo "✅ Add complete. Verifying..."
qmd list --collection "$COLLECTION" --detailed | head -20
