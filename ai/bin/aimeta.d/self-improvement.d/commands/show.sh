#!/usr/bin/env bash
# self-improvement show - Display detailed entry

# Source shared utilities
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
  HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_show_usage() {
  cat <<EOF
${SCRIPT_NAME} show - Display detailed feedback entry

USAGE:
  ${SCRIPT_NAME} show <id> [options]

OPTIONS:
  --json              Output as JSON
  --markdown          Output as markdown
  --resolve           Mark entry as resolved
  --help              Show this help message

EXAMPLES:

Show entry details:
  $ ${SCRIPT_NAME} show 20260220T105345Z

Show as JSON:
  $ ${SCRIPT_NAME} show 20260220T105345Z --json

Show and mark as resolved:
  $ ${SCRIPT_NAME} show 20260220T105345Z --resolve
EOF
}

cmd_show() {
  local entry_id=""
  local output_format="text"
  local mark_resolved=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        output_format="json"
        shift
        ;;
      --markdown)
        output_format="markdown"
        shift
        ;;
      --resolve)
        mark_resolved=true
        shift
        ;;
      --help|-h)
        cmd_show_usage
        exit 0
        ;;
      -*)
        echo "Error: Unknown option '$1'" >&2
        cmd_show_usage >&2
        exit 1
        ;;
      *)
        if [[ -z "$entry_id" ]]; then
          entry_id="$1"
        else
          echo "Error: Only one entry ID expected" >&2
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$entry_id" ]]; then
    echo "Error: Entry ID is required" >&2
    cmd_show_usage >&2
    exit 1
  fi

  init_storage

  # Get entry
  local entry
  entry=$(get_entry "$entry_id")

  if [[ "$entry" == "null" ]]; then
    echo "Error: Entry not found: $entry_id" >&2
    exit 1
  fi

  # Mark as resolved if requested
  if [[ "$mark_resolved" == true ]]; then
    update_entry_field "$entry_id" "resolved" "true"
    echo -e "${GREEN}✓ Entry marked as resolved${RESET}"
    echo ""
  fi

  # Output based on format
  case "$output_format" in
    json)
      echo "$entry" | jq .
      ;;
    markdown)
      export_entry_markdown "$entry"
      ;;
    text|*)
      display_entry_text "$entry"
      ;;
  esac
}

# Display entry in text format
display_entry_text() {
  local entry="$1"
  
  local id timestamp agent category severity correction context tags resolved skill_linked session_id
  id=$(echo "$entry" | jq -r '.id')
  timestamp=$(echo "$entry" | jq -r '.timestamp')
  agent=$(echo "$entry" | jq -r '.agent')
  category=$(echo "$entry" | jq -r '.category')
  severity=$(echo "$entry" | jq -r '.severity')
  correction=$(echo "$entry" | jq -r '.correction')
  context=$(echo "$entry" | jq -r '.context')
  tags=$(echo "$entry" | jq -r '.tags | join(", ")')
  resolved=$(echo "$entry" | jq -r '.resolved')
  skill_linked=$(echo "$entry" | jq -r '.skill_linked')
  session_id=$(echo "$entry" | jq -r '.session_id')

  # Status color
  local status_color status_str
  if [[ "$resolved" == "true" ]]; then
    status_color="${GREEN}"
    status_str="✓ RESOLVED"
  else
    status_color="${YELLOW}"
    status_str="○ OPEN"
  fi

  # Severity color
  local severity_color
  case "$severity" in
    high) severity_color="${RED}" ;;
    medium) severity_color="${YELLOW}" ;;
    low) severity_color="${GREEN}" ;;
  esac

  echo -e "${BOLD}Self-Improvement Entry${RESET}"
  echo ""
  
  # Header
  echo -e "${BOLD}ID:${RESET}        $id"
  echo -e "${BOLD}Status:${RESET}     ${status_color}${status_str}${RESET}"
  echo -e "${BOLD}Timestamp:${RESET}  $timestamp"
  echo ""
  
  # Metadata
  echo -e "${BOLD}Metadata:${RESET}"
  echo "  Agent:    $agent"
  echo "  Category: $category"
  echo -e "  Severity: ${severity_color}${severity}${RESET}"
  [[ -n "$tags" ]] && [[ "$tags" != "null" ]] && echo "  Tags:     $tags"
  [[ -n "$skill_linked" ]] && [[ "$skill_linked" != "null" ]] && echo "  Skill:    $skill_linked"
  [[ -n "$session_id" ]] && [[ "$session_id" != "null" ]] && echo "  Session:  $session_id"
  echo ""
  
  # Correction
  echo -e "${BOLD}Correction:${RESET}"
  echo "  $correction"
  echo ""
  
  # Context
  echo -e "${BOLD}Details:${RESET}"
  echo "$context" | sed 's/^/  /'
  echo ""
  
  # Actions
  echo -e "${BOLD}Actions:${RESET}"
  echo "  View as JSON:      ${CYAN}${SCRIPT_NAME} show $id --json${RESET}"
  echo "  View as Markdown:  ${CYAN}${SCRIPT_NAME} show $id --markdown${RESET}"
  if [[ "$resolved" == "false" ]]; then
    echo "  Mark resolved:     ${CYAN}${SCRIPT_NAME} show $id --resolve${RESET}"
    echo "  Link to skill:     ${CYAN}${SCRIPT_NAME} link-skill $id --skill <skill-name>${RESET}"
  fi
}
