#!/usr/bin/env bash
# self-improvement clean - Archive or delete old feedback

# Source shared utilities
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
  HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_clean_usage() {
  cat <<EOF
${SCRIPT_NAME} clean - Archive or delete old feedback entries

USAGE:
  ${SCRIPT_NAME} clean [options]

OPTIONS:
  --action ACTION     Action: archive or delete (required)
  --days N            Remove entries older than N days (default: 30)
  --category CATEGORY Only clean specific category
  --resolved          Only clean resolved entries
  --force             Skip confirmation prompt
  --help              Show this help message

DESCRIPTION:
  Archive or permanently delete old feedback entries. Archiving
  moves entries to an archive directory, while delete removes them.

  Use with caution! Always archive before deleting if unsure.

EXAMPLES:

Archive entries older than 30 days:
  $ ${SCRIPT_NAME} clean --action archive --days 30

Delete entries older than 90 days:
  $ ${SCRIPT_NAME} clean --action delete --days 90

Archive resolved entries older than 60 days:
  $ ${SCRIPT_NAME} clean --action archive --days 60 --resolved

Delete old git-related entries:
  $ ${SCRIPT_NAME} clean --action delete --days 90 --category git --force
EOF
}

cmd_clean() {
  local action=""
  local days=30
  local category_filter=""
  local resolved_only=false
  local force=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --action)
        action="$2"
        shift 2
        ;;
      --days)
        days="$2"
        shift 2
        ;;
      --category)
        category_filter="$2"
        shift 2
        ;;
      --resolved)
        resolved_only=true
        shift
        ;;
      --force)
        force=true
        shift
        ;;
      --help|-h)
        cmd_clean_usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option '$1'" >&2
        cmd_clean_usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$action" ]]; then
    echo "Error: --action is required (archive or delete)" >&2
    cmd_clean_usage >&2
    exit 1
  fi

  if [[ "$action" != "archive" && "$action" != "delete" ]]; then
    echo "Error: Invalid action '$action'. Use 'archive' or 'delete'" >&2
    exit 1
  fi

  init_storage

  # Calculate cutoff date
  local cutoff_date
  if command -v date >/dev/null 2>&1; then
    # Try GNU date first (Linux)
    if date --version >/dev/null 2>&1; then
      cutoff_date=$(date -d "$days days ago" -u '+%Y-%m-%dT%H:%M:%SZ')
    else
      # macOS date
      cutoff_date=$(date -v-${days}d -u '+%Y-%m-%dT%H:%M:%SZ')
    fi
  else
    echo "Error: date command not found" >&2
    exit 1
  fi

  # Get entries to clean
  local entries_to_clean=()
  local count=0

  for file in "$ENTRIES_DIR"/*.json; do
    [[ -f "$file" ]] || continue
    
    local entry
    entry=$(cat "$file")
    
    local timestamp
    timestamp=$(echo "$entry" | jq -r '.timestamp')
    
    # Check if entry is old enough
    if [[ "$timestamp" < "$cutoff_date" ]]; then
      # Apply additional filters
      if [[ -n "$category_filter" ]]; then
        local entry_category
        entry_category=$(echo "$entry" | jq -r '.category')
        if [[ "$entry_category" != "$category_filter" ]]; then
          continue
        fi
      fi
      
      if [[ "$resolved_only" == true ]]; then
        local resolved
        resolved=$(echo "$entry" | jq -r '.resolved')
        if [[ "$resolved" != "true" ]]; then
          continue
        fi
      fi
      
      entries_to_clean+=("$file")
      ((count++))
    fi
  done

  if [[ $count -eq 0 ]]; then
    echo "No entries matching criteria for $action"
    return
  fi

  # Confirm action
  if [[ "$force" == false ]]; then
    echo "${YELLOW}WARNING:${RESET} About to $action $count entries (older than $days days)"
    if [[ -n "$category_filter" ]]; then
      echo "  Category filter: $category_filter"
    fi
    if [[ "$resolved_only" == true ]]; then
      echo "  Only resolved entries"
    fi
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Operation cancelled"
      return
    fi
  fi

  # Perform action
  case "$action" in
    archive)
      local archive_dir="${DATA_DIR}/archive"
      mkdir -p "$archive_dir"
      
      for file in "${entries_to_clean[@]}"; do
        mv "$file" "$archive_dir/"
      done
      
      echo -e "${GREEN}✓ Archived $count entries${RESET}"
      echo "Archive location: $archive_dir"
      ;;
    delete)
      for file in "${entries_to_clean[@]}"; do
        rm "$file"
      done
      
      echo -e "${RED}✗ Deleted $count entries${RESET}"
      echo "This action cannot be undone"
      ;;
  esac

  # Update statistics
  echo ""
  echo "Updated statistics:"
  echo "  Total entries now: $(count_total_entries)"
}

# Count total entries
count_total_entries() {
  init_storage
  local count
  count=$(get_all_entries | jq 'length')
  echo "$count"
}
