#!/usr/bin/env bash
# self-improvement export - Export feedback for skill creation

# Source shared utilities
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
  HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_export_usage() {
  cat <<EOF
${SCRIPT_NAME} export - Export feedback for skill creation

USAGE:
  ${SCRIPT_NAME} export [options]

OPTIONS:
  --agent AGENT       Filter by agent
  --category CATEGORY Filter by category
  --severity LEVEL    Filter by severity (high|medium|low)
  --unresolved        Export only unresolved entries
  --resolved          Export only resolved entries
  --format FORMAT     Output format: markdown (default) or json
  --output FILE       Write to file instead of stdout
  --template TYPE     Use template: full or summary (default: full)
  --help              Show this help message

DESCRIPTION:
  Export feedback entries in a format suitable for creating skills.
  Markdown format includes all context and is ready for documentation.
  JSON format preserves full structure for programmatic processing.

TEMPLATES:
  full    - Complete entry with all details (default)
  summary - Condensed version suitable for quick review

EXAMPLES:

Export all high-severity items as markdown:
  $ ${SCRIPT_NAME} export --severity high --format markdown

Export unresolved items by agent:
  $ ${SCRIPT_NAME} export --agent task-worker --unresolved

Save to file:
  $ ${SCRIPT_NAME} export --severity high > improvements.md

Export as JSON:
  $ ${SCRIPT_NAME} export --agent janitor --format json

Export with summary template:
  $ ${SCRIPT_NAME} export --unresolved --template summary
EOF
}

cmd_export() {
  local agent_filter=""
  local category_filter=""
  local severity_filter=""
  local resolved_filter=""
  local output_format="markdown"
  local output_file=""
  local template="full"

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
      --unresolved)
        resolved_filter="false"
        shift
        ;;
      --resolved)
        resolved_filter="true"
        shift
        ;;
      --format)
        output_format="$2"
        shift 2
        ;;
      --output)
        output_file="$2"
        shift 2
        ;;
      --template)
        template="$2"
        shift 2
        ;;
      --help|-h)
        cmd_export_usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        cmd_export_usage >&2
        exit 1
        ;;
    esac
  done

  init_storage

  # Get all entries
  local all_entries
  all_entries=$(get_all_entries)

  # Apply filters
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

  # Get filtered entries
  local filtered
  filtered=$(echo "$all_entries" | jq "[.[] | $jq_filter] | sort_by(.timestamp) | reverse")

  local count
  count=$(echo "$filtered" | jq 'length')

  if [[ "$count" -eq 0 ]]; then
    echo "No entries matching filters" >&2
    return
  fi

  # Build output
  local output=""
  case "$output_format" in
    markdown)
      output=$(export_as_markdown "$filtered" "$template")
      ;;
    json)
      output=$(echo "$filtered" | jq .)
      ;;
    *)
      echo "Error: Unknown format '$output_format'" >&2
      exit 1
      ;;
  esac

  # Write output
  if [[ -n "$output_file" ]]; then
    echo "$output" > "$output_file"
    echo "Exported $count entries to $output_file" >&2
  else
    echo "$output"
  fi
}

# Export entries as markdown
export_as_markdown() {
  local entries="$1"
  local template="${2:-full}"

  local title="# Self-Improvement Export"
  local date
  date=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
  local count
  count=$(echo "$entries" | jq 'length')

  cat <<EOF
${title}

**Exported:** ${date}
**Total Entries:** ${count}

---

EOF

  if [[ "$template" == "summary" ]]; then
    export_markdown_summary "$entries"
  else
    export_markdown_full "$entries"
  fi
}

# Export with full details
export_markdown_full() {
  local entries="$1"

  echo "$entries" | jq -r '.[] |
    "## " + .correction + "\n" +
    "\n**ID:** `" + .id + "`\n" +
    "**Agent:** " + .agent + "\n" +
    "**Category:** " + .category + "\n" +
    "**Severity:** " + .severity + "\n" +
    "**Status:** " + (if .resolved then "✓ Resolved" else "○ Open" end) + "\n" +
    "\n### Context\n\n" +
    .context + "\n\n" +
    (if (.tags | length) > 0 then "**Tags:** " + (.tags | join(", ")) + "\n\n" else "" end) +
    (if .skill_linked != null then "**Linked Skill:** " + .skill_linked + "\n\n" else "" end) +
    "---\n\n"
  '
}

# Export with summary
export_markdown_summary() {
  local entries="$1"

  # Count by severity
  local high_count medium_count low_count
  high_count=$(echo "$entries" | jq '[.[] | select(.severity == "high")] | length')
  medium_count=$(echo "$entries" | jq '[.[] | select(.severity == "medium")] | length')
  low_count=$(echo "$entries" | jq '[.[] | select(.severity == "low")] | length')

  cat <<EOF
## Summary

- **High Priority:** $high_count items
- **Medium Priority:** $medium_count items
- **Low Priority:** $low_count items

---

## High-Priority Items

EOF

  echo "$entries" | jq -r '.[] | select(.severity == "high") |
    "### " + .correction + "\n" +
    "\n**Agent:** " + .agent + " | **Category:** " + .category + "\n" +
    "\n" +
    .context + "\n" +
    "\n"
  '

  cat <<EOF

---

## Medium-Priority Items

EOF

  echo "$entries" | jq -r '.[] | select(.severity == "medium") | .correction' | nl -w 1 -s '. '

  cat <<EOF

---

## Low-Priority Items

EOF

  echo "$entries" | jq -r '.[] | select(.severity == "low") | .correction' | nl -w 1 -s '. '
}
