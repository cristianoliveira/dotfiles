#!/bin/bash
# Quick search helper for qmd knowledge base
# Usage: ./quick_search.sh "search query" [collection] [limit]

set -e

QUERY="${1:-}"
COLLECTION="${2:-}"
LIMIT="${3:-10}"

if [ -z "$QUERY" ]; then
	echo "Usage: quick_search.sh \"search query\" [collection] [limit]"
	echo ""
	echo "Examples:"
	echo "  ./quick_search.sh \"docker architecture\""
	echo "  ./quick_search.sh \"api design\" api-docs 20"
	echo "  ./quick_search.sh \"kubernetes\" devops-research"
	exit 1
fi

echo "🔍 Searching: $QUERY"
if [ -n "$COLLECTION" ]; then
	echo "📚 Collection: $COLLECTION"
fi
echo "📊 Results limit: $LIMIT"
echo ""

if [ -z "$COLLECTION" ]; then
	qmd search "$QUERY" --top "$LIMIT" --pretty
else
	qmd search "$QUERY" --collection "$COLLECTION" --top "$LIMIT" --pretty
fi
