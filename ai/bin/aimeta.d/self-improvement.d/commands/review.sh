#!/usr/bin/env bash
# self-improvement review-session - Batch review feedback

# Source shared utilities
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
  HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_review_usage() {
  cat <<EOF
${SCRIPT_NAME} review-session - Batch review feedback entries

USAGE:
  ${SCRIPT_NAME} review-session [options]

OPTIONS:
  --unresolved        Review only unresolved entries
  --agent AGENT       Filter by agent
  --category CATEGORY Filter by category
  --severity LEVEL    Filter by severity
  --limit N           Limit to N entries (default: 10)
  --help              Show this help message

DESCRIPTION:
  Interactive session to review feedback entries one by one.
  For each entry, you can:
    (r) Mark as resolved
    (s) Link to skill
    (n) Next entry
    (q) Quit

EXAMPLES:

Review unresolved entries:
  $ ${SCRIPT_NAME} review-session --unresolved

Review high-severity items:
  $ ${SCRIPT_NAME} review-session --severity high

Review by agent:
  $ ${SCRIPT_NAME} review-session --agent task-worker --unresolved

Limit to 5 entries:
  $ ${SCRIPT_NAME} review-session --unresolved --limit 5
EOF
}

cmd_review_session() {
  local unresolved_only=false
  local agent_filter=""
  local category_filter=""
  local severity_filter=""
  local limit=10

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --unresolved)
        unresolved_only=true
        shift
        ;;
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
      --limit)
        limit="$2"
        shift 2
        ;;
      --help|-h)
        cmd_review_usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        cmd_review_usage >&2
        exit 1
        ;;
    esac
  done

  init_storage

  # Get entries
  local all_entries
  all_entries=$(get_all_entries)

  # Apply filters
  local jq_filter='.'
  
  if [[ "$unresolved_only" == true ]]; then
    jq_filter="$jq_filter | select(.resolved == false)"
  fi
  
  if [[ -n "$agent_filter" ]]; then
    jq_filter="$jq_filter | select(.agent == \"$agent_filter\")"
  fi
  
  if [[ -n "$category_filter" ]]; then
    jq_filter="$jq_filter | select(.category == \"$category_filter\")"
  fi
  
  if [[ -n "$severity_filter" ]]; then
    jq_filter="$jq_filter | select(.severity == \"$severity_filter\")"
  fi

  # Get filtered entries, limit to N
  local filtered
  filtered=$(echo "$all_entries" | jq "[.[] | $jq_filter] | sort_by(.severity != \"high\", .timestamp) | .[0:$limit]")

  local count
  count=$(echo "$filtered" | jq 'length')

  if [[ "$count" -eq 0 ]]; then
    echo "No entries matching filter"
    return
  fi

  echo -e "${BOLD}Review Session - $count Entries${RESET}"
  echo ""

  local current=0
  while [[ $current -lt $count ]]; do
    local entry
    entry=$(echo "$filtered" | jq ".[$current]")
    
    review_entry "$entry" "$current" "$count"
    
    read -p "Action (r=resolve, s=skill, n=next, q=quit): " -n 1 -r action
    echo
    
    case "$action" in
      r)
        local id
        id=$(echo "$entry" | jq -r '.id')
        update_entry_field "$id" "resolved" "true"
        echo -e "${GREEN}✓ Marked as resolved${RESET}"
        ((current++))
        ;;
      s)
        link_skill_interactive "$entry"
        ((current++))
        ;;
      n|'')
        ((current++))
        ;;
      q)
        echo "Review session ended"
        break
        ;;
      *)
        echo "Unknown action"
        ;;
    esac
    
    if [[ $current -lt $count ]]; then
      echo ""
    fi
  done

  echo ""
  echo -e "${BOLD}Review session complete!${RESET}"
  echo "View updated stats with: ${CYAN}${SCRIPT_NAME} stats${RESET}"
}

# Display entry for review
review_entry() {
  local entry="$1"
  local current="$2"
  local total="$3"

  local id severity correction context agent category
  id=$(echo "$entry" | jq -r '.id')
  severity=$(echo "$entry" | jq -r '.severity')
  correction=$(echo "$entry" | jq -r '.correction')
  context=$(echo "$entry" | jq -r '.context')
  agent=$(echo "$entry" | jq -r '.agent')
  category=$(echo "$entry" | jq -r '.category')

  # Severity color
  local severity_color
  case "$severity" in
    high) severity_color="${RED}" ;;
    medium) severity_color="${YELLOW}" ;;
    low) severity_color="${GREEN}" ;;
  esac

  echo -e "${BOLD}[$((current + 1))/$total]${RESET}"
  echo -e "${BOLD}ID:${RESET}        $id"
  echo -e "${BOLD}Severity:${RESET}   ${severity_color}${severity}${RESET}"
  echo -e "${BOLD}Agent:${RESET}     $agent ($category)"
  echo ""
  echo -e "${BOLD}Correction:${RESET}"
  echo "  $correction"
  echo ""
  echo -e "${BOLD}Details:${RESET}"
  echo "$context" | sed 's/^/  /' | head -5
  if [[ $(echo "$context" | wc -l) -gt 5 ]]; then
    echo "  ..."
  fi
  echo ""
}

# Interactive skill linking
link_skill_interactive() {
  local entry="$1"
  local id
  id=$(echo "$entry" | jq -r '.id')

  echo "Enter skill name to link (or leave blank to skip):"
  read -r skill_name

  if [[ -n "$skill_name" ]]; then
    update_entry_field "$id" "skill_linked" "$skill_name"
    echo -e "${GREEN}✓ Linked to skill: $skill_name${RESET}"
  fi
}
