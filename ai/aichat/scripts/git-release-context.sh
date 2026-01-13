#!/bin/sh

LAST_TAG="$(git describe --tags $(git rev-list --tags --max-count=2) | tail -n 1)"
NEXT_TAG="$(git describe --tags $(git rev-list --tags --max-count=1))"

LAST_REF="${1:-$LAST_TAG}"
CURRENT_REF="${2:-$NEXT_TAG}"
echo "The last tag was $LAST_TAG and the next tag is $NEXT_TAG"

echo "{{git_log}} The commit list between last tag and next tag is"
echo "---"
echo "$(git -c log.showSignature=false log $LAST_REF..$CURRENT_REF --pretty=format:'%H|%an|%ad|%s%n%b' --date=short | grep -v '(nix)')"
echo "---"

echo "{{git_diff}} The diff between last tag and next tag is"
echo "---\n$(git diff $LAST_REF..$CURRENT_REF)\n---"

echo "{{latest_tag}} The latest tag is follow the same pattern for the next"
echo "---\n$LAST_TAG\n---"
