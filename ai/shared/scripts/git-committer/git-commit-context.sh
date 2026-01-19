#!/bin/sh

echo "Use the same pattern for your commit message, specially the feat/fix/etc(context): title"
echo "---"
echo "$(git log --oneline -n 10 -- $(git diff --name-only --cached))"
echo "---"
echo ""
echo "These are the changes that will be committed:"
echo "---"
echo `git diff --cached`
echo "---"
