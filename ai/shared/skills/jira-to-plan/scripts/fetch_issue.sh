#!/usr/bin/env bash
set -euo pipefail

JIRA_URL="${1:-}"

if [[ -z "$JIRA_URL" ]]; then
  echo "Usage: fetch_issue.sh <JIRA_URL>" >&2
  exit 1
fi

# Extract ISSUE_KEY from common Jira URL formats
# Examples:
#   https://jira.example.com/browse/PROJ-123
#   https://jira.example.com/secure/RapidBoard.jspa?selectedIssue=PROJ-123
if [[ "$JIRA_URL" =~ ([A-Z][A-Z0-9]+-[0-9]+) ]]; then
  ISSUE_KEY="${BASH_REMATCH[1]}"
else
  echo "ERROR: Could not extract Jira issue key from URL: $JIRA_URL" >&2
  exit 1
fi

# Fetch issue using jira-cli
if jira issue view "$ISSUE_KEY" --comments 0 >/dev/null 2>&1; then
  jira issue view "$ISSUE_KEY" --comments 0
else
  jira issue view "$ISSUE_KEY"
fi

