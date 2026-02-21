#!/usr/bin/env bash
# self-improvement stats - Show statistics and insights

# Source shared utilities
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
  HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_stats_usage() {
  cat <<EOF
${SCRIPT_NAME} stats - Show statistics and insights

USAGE:
  ${SCRIPT_NAME} stats [options]

OPTIONS:
  --json              Output as JSON
  --help              Show this help message

EXAMPLES:

Show all statistics:
  $ ${SCRIPT_NAME} stats

Output as JSON:
  $ ${SCRIPT_NAME} stats --json
EOF
}

cmd_stats() {
  local output_format="text"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        output_format="json"
        shift
        ;;
      --help|-h)
        cmd_stats_usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        cmd_stats_usage >&2
        exit 1
        ;;
    esac
  done

  init_storage

  # Get all entries
  local all_entries
  all_entries=$(get_all_entries)

  if [[ "$output_format" == "json" ]]; then
    echo "$all_entries" | jq 'group_by(.agent,.category,.severity) | map({
      agent: .[0].agent,
      category: .[0].category,
      severity: .[0].severity,
      count: length
    })'
    return
  fi

  # Calculate statistics for text output
  local total_count resolved_count unresolved_count
  total_count=$(echo "$all_entries" | jq 'length')
  resolved_count=$(echo "$all_entries" | jq '[.[] | select(.resolved == true)] | length')
  unresolved_count=$((total_count - resolved_count))
  
  local high_unresolved
  high_unresolved=$(echo "$all_entries" | jq '[.[] | select(.severity == "high" and .resolved == false)] | length')

  if [[ "$total_count" -eq 0 ]]; then
    echo "No feedback entries recorded yet."
    echo ""
    echo "Start capturing feedback with:"
    echo "  ${CYAN}${SCRIPT_NAME} add${RESET}"
    return
  fi

  echo -e "${BOLD}Self-Improvement Statistics${RESET}"
  echo ""
  
  # Summary
  echo -e "${BOLD}Summary:${RESET}"
  echo "  Total entries:      $total_count"
  echo -e "  ${GREEN}✓ Resolved:${RESET}        $resolved_count"
  echo -e "  ${YELLOW}○ Unresolved:${RESET}      $unresolved_count"
  
  if [[ "$high_unresolved" -gt 0 ]]; then
    echo -e "  ${RED}⚠ High severity open:${RESET}  $high_unresolved"
  fi
  echo ""
  
  # By Agent
  echo -e "${BOLD}By Agent:${RESET}"
  echo "$all_entries" | jq -r '.[] | .agent' | sort | uniq -c | sort -rn | while read count agent; do
    echo "  $agent: $count"
  done
  echo ""
  
  # By Category
  echo -e "${BOLD}By Category:${RESET}"
  echo "$all_entries" | jq -r '.[] | .category' | sort | uniq -c | sort -rn | while read count category; do
    echo "  $category: $count"
  done
  echo ""
  
  # By Severity
  echo -e "${BOLD}By Severity:${RESET}"
  echo "  high:   $(echo "$all_entries" | jq '[.[] | select(.severity == "high")] | length')"
  echo "  medium: $(echo "$all_entries" | jq '[.[] | select(.severity == "medium")] | length')"
  echo "  low:    $(echo "$all_entries" | jq '[.[] | select(.severity == "low")] | length')"
  echo ""

  # Trends
  echo -e "${BOLD}Trends:${RESET}"
  if [[ "$unresolved_count" -gt 0 ]]; then
    local pct=$((unresolved_count * 100 / total_count))
    echo -e "  ${YELLOW}Action needed:${RESET} $pct% of entries are unresolved"
  fi
  
  if [[ "$high_unresolved" -gt 0 ]]; then
    echo -e "  ${RED}Alert:${RESET} $high_unresolved high-severity items need attention"
  fi
  
  if [[ "$resolved_count" -eq "$total_count" ]]; then
    echo -e "  ${GREEN}All feedback has been resolved!${RESET}"
  fi
  echo ""
}
