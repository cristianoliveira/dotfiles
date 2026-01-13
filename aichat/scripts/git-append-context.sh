#!/bin/sh

CURRENT=${1:-"HEAD"}
BEFORE=${2:-"HEAD~1"}

if [ -z "$CURRENT" ]; then
    echo "Usage: git-append-context.sh <tag_from> <tag_to>"
    exit 1
fi

echo "Use the same pattern for your commit message, specially the feat/fix/etc(context): title"
echo "---"
echo "$(git log --oneline -n 10 -- $(git diff --name-only --cached))"
echo "---"
echo ""
echo "These are the changes that are being ammended:"
echo "---"
echo `git diff --cached $BEFORE $CURRENT`
echo "---"
