#!/bin/sh

echo "These are the last commits on the changed files. Use the same pattern for your commit message:"
echo "---"
echo "$(git log --oneline -n 10 -- $(git diff --name-only --cached))"
echo "---"
echo ""
echo "These are the changes that will be committed:"
echo "---"
echo `git diff --cached`
echo "---"
