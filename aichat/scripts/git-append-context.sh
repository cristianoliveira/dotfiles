#!/bin/sh

CURRENT=${1:-HEAD}
BEFORE=${2:-HEAD~1}

echo "Use the same pattern for your commit message, specially the feat/fix/etc(context): title"
echo "---"
echo "$(git log --oneline -n 10 -- $(git diff --name-only --cached))"
echo "---"
echo ""
echo "These are the changes that are being appended:"
echo "---"
echo `git diff --cached $BEFORE $CURRENT`
echo "---"
