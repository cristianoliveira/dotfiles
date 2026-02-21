#!/usr/bin/env bash
# self-improvement list - View and filter feedback entries

# Source shared utilities
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
  HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_list_usage() {
  cat <<EOF
${SCRIPT_NAME} list - View and filter feedback entries

USAGE:
  ${SCRIPT_NAME} list [options]

OPTIONS:
  --agent AGENT          Filter by agent type
  --category CATEGORY    Filter by category
  --severity LEVEL       Filter by severity (high|medium|low)
  --resolved             Show only resolved entries
  --unresolved           Show only unresolved entries
  --json                 Output as JSON
  --count                Show count only
  --help                 Show this help message

EXAMPLES:

List all entries:
  $ ${SCRIPT_NAME} list

Filter by agent:
  $ ${SCRIPT_NAME} list --agent task-worker

Filter by category:
  $ ${SCRIPT_NAME} list --category git

Filter by severity:
  $ ${SCRIPT_NAME} list --severity high

Show only unresolved:
  $ ${SCRIPT_NAME} list --unresolved

Output as JSON:
  $ ${SCRIPT_NAME} list --json

Count entries:
  $ ${SCRIPT_NAME} list --count
EOF
}

cmd_list() {
  local agent_filter=""
  local category_filter=""
  local severity_filter=""
  local resolved_filter=""
  local output_format="table"
  local count_only=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent)
        agent_filter="$2"
        shift 2
        ;;
      --category)
        category_filter="$2"
        shift 2
        ;;
      --severity)
        severity_filter="$2"
        shift 2
        ;;
      --resolved)
        resolved_filter="true"
        shift
        ;;
      --unresolved)
        resolved_filter="false"
        shift
        ;;
      --json)
        output_format="json"
        shift
        ;;
      --count)
        count_only=true
        shift
        ;;
      --help|-h)
        cmd_list_usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        cmd_list_usage >&2
        exit 1
        ;;
    esac
  done

  init_storage

  # Build jq filter
  local jq_filter='.'
  
  if [[ -n "$agent_filter" ]]; then
    jq_filter="$jq_filter | select(.agent == \"$agent_filter\")"
  fi
  
  if [[ -n "$category_filter" ]]; then
    jq_filter="$jq_filter | select(.category == \"$category_filter\")"
  fi
  
  if [[ -n "$severity_filter" ]]; then
    jq_filter="$jq_filter | select(.severity == \"$severity_filter\")"
  fi
  
  if [[ -n "$resolved_filter" ]]; then
    if [[ "$resolved_filter" == "true" ]]; then
      jq_filter="$jq_filter | select(.resolved == true)"
    else
      jq_filter="$jq_filter | select(.resolved == false)"
    fi
  fi

  # Get all entries
  local all_entries
  all_entries=$(get_all_entries)
  
  # Apply filters and sort (newest first)
  local filtered
  filtered=$(echo "$all_entries" | jq "[.[] | $jq_filter] | sort_by(.timestamp) | reverse")

  # Count entries
  local count
  count=$(echo "$filtered" | jq 'length')

  if [[ "$count_only" == true ]]; then
    echo "$count"
    return
  fi

  if [[ "$count" -eq 0 ]]; then
    echo "No entries found matching filters"
    return
  fi

  # Output results
  case "$output_format" in
    json)
      echo "$filtered" | jq .
      ;;
    table)
      echo -e "${BOLD}Self-Improvement Entries ($count total)${RESET}\n"
      echo "$filtered" | jq -r '.[] | "\(if .resolved then "✓" else "○" end)   \(.id)   \(.correction | .[0:40])   \(.agent)   \(.category)   \(.severity)"'
      echo ""
      echo "Legend: ✓ = Resolved, ○ = Open"
      echo ""
      echo "View details: ${CYAN}${SCRIPT_NAME} show <id>${RESET}"
      ;;
  esac
}
