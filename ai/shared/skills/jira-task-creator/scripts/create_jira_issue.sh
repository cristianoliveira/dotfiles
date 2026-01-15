#!/usr/bin/env bash
# Script to create Jira issue from gathered parameters
# Usage: ./create_jira_issue.sh [options]

set -euo pipefail

# Default values
PROJECT=""
SUMMARY=""
TYPE="Task"
BODY=""
PRIORITY=""
LABELS=()
COMPONENTS=()
ASSIGNEE=""
PARENT=""
AUTO_CREATE=true

# Parse arguments (simplified example)
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project) PROJECT="$2"; shift 2 ;;
        -s|--summary) SUMMARY="$2"; shift 2 ;;
        -t|--type) TYPE="$2"; shift 2 ;;
        -b|--body) BODY="$2"; shift 2 ;;
        -y|--priority) PRIORITY="$2"; shift 2 ;;
        -l|--label) LABELS+=("$2"); shift 2 ;;
        -C|--component) COMPONENTS+=("$2"); shift 2 ;;
        -a|--assignee) ASSIGNEE="$2"; shift 2 ;;
        -P|--parent) PARENT="$2"; shift 2 ;;
        --dry-run) AUTO_CREATE=false; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate required fields
if [[ -z "$PROJECT" ]]; then
    echo "Error: Project key is required" >&2
    exit 1
fi

if [[ -z "$SUMMARY" ]]; then
    echo "Error: Summary is required" >&2
    exit 1
fi

# Build command
CMD="jira issue create -p '$PROJECT' -t '$TYPE' -s '$SUMMARY'"

if [[ -n "$BODY" ]]; then
    # Use temporary file for body to handle multiline
    TEMP_FILE=$(mktemp)
    echo "$BODY" > "$TEMP_FILE"
    CMD="$CMD --template '$TEMP_FILE'"
fi

if [[ -n "$PRIORITY" ]]; then
    CMD="$CMD -y '$PRIORITY'"
fi

for label in "${LABELS[@]}"; do
    CMD="$CMD -l '$label'"
done

for component in "${COMPONENTS[@]}"; do
    CMD="$CMD -C '$component'"
done

if [[ -n "$ASSIGNEE" ]]; then
    CMD="$CMD -a '$ASSIGNEE'"
fi

if [[ -n "$PARENT" ]]; then
    CMD="$CMD -P '$PARENT'"
fi

echo "Command to execute:"
echo "$CMD"

if [[ "$AUTO_CREATE" == true ]]; then
    echo "Creating issue..."
    eval "$CMD"
    
    # Cleanup temp file if created
    if [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]]; then
        rm "$TEMP_FILE"
    fi
else
    echo "Dry run - issue not created"
fi