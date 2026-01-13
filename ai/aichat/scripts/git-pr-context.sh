#!/bin/sh

echo "Use this context for generating the pull request description:"
echo "---"
echo "These are the last commits on the changed files:"
echo "---\n$(git log origin/$MAIN_BRANCH..HEAD --summary --pretty=oneline)\n---"
echo "These are the changes that will be committed:"
echo "---\n$(git diff origin/$MAIN_BRANCH)\n---"
if [ -f .tmp/changes.txt ]; then
  echo "Use this as extra context about the changes:"
  echo "---\n$(cat .tmp/changes.txt)\n---"
fi
if [ -z "$2" ]; then
  echo "no more context"
else
  echo "$1"
fi
