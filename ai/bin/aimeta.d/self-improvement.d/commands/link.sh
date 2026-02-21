#!/usr/bin/env bash
# self-improvement link-skill - Link feedback to skills

# Source shared utilities
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
  HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_link_usage() {
  cat <<EOF
${SCRIPT_NAME} link-skill - Link feedback entry to a skill

USAGE:
  ${SCRIPT_NAME} link-skill <id> [options]

OPTIONS:
  --skill NAME        Name of the skill to link (required)
  --help              Show this help message

DESCRIPTION:
  Link a feedback entry to a skill. This helps track which feedback
  has been converted into skills and maintains the connection between
  discoveries and implementations.

EXAMPLES:

Link entry to skill:
  $ ${SCRIPT_NAME} link-skill 20260220T105345Z --skill land-the-plane

List entries linked to a skill:
  $ ${SCRIPT_NAME} list | grep -A1 'land-the-plane'

View entries with no skill link:
  $ ${SCRIPT_NAME} list --unresolved
EOF
}

cmd_link_skill() {
  local entry_id=""
  local skill_name=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skill)
        skill_name="$2"
        shift 2
        ;;
      --help|-h)
        cmd_link_usage
        exit 0
        ;;
      -*)
        echo "Error: Unknown option '$1'" >&2
        cmd_link_usage >&2
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
    cmd_link_usage >&2
    exit 1
  fi

  if [[ -z "$skill_name" ]]; then
    echo "Error: --skill is required" >&2
    cmd_link_usage >&2
    exit 1
  fi

  init_storage

  # Check if entry exists
  if ! entry_exists "$entry_id"; then
    echo "Error: Entry not found: $entry_id" >&2
    exit 1
  fi

  # Update skill link
  update_entry_field "$entry_id" "skill_linked" "$skill_name"

  echo -e "${GREEN}✓ Entry linked to skill: $skill_name${RESET}"
  echo ""
  echo "View entry:"
  echo "  ${CYAN}${SCRIPT_NAME} show $entry_id${RESET}"
}
