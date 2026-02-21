#!/usr/bin/env bash
# self-improvement - Shared utilities

_SELF_IMPROVEMENT_UTILS_LOADED=1

# Initialize storage directories
init_storage() {
	mkdir -p "$ENTRIES_DIR"
	if [[ ! -f "$INDEX_FILE" ]]; then
		echo '[]' >"$INDEX_FILE"
	fi
}

# Check if array contains element
array_contains() {
	local element="$1"
	shift
	local array=("$@")

	for item in "${array[@]}"; do
		if [[ "$item" == "$element" ]]; then
			return 0
		fi
	done
	return 1
}

# Get all entries
get_all_entries() {
	init_storage
	if [[ ! -d "$ENTRIES_DIR" ]]; then
		echo "[]"
		return
	fi

	local entries=()
	for file in "$ENTRIES_DIR"/*.json; do
		[[ -f "$file" ]] && entries+=("$(cat "$file")")
	done

	if [[ ${#entries[@]} -eq 0 ]]; then
		echo "[]"
	else
		printf '%s\n' "${entries[@]}" | jq -s .
	fi
}

# Filter entries by criteria
filter_entries() {
	local agent_filter="${1:-}"
	local category_filter="${2:-}"
	local severity_filter="${3:-}"
	local resolved_filter="${4:-}"

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
		elif [[ "$resolved_filter" == "false" ]]; then
			jq_filter="$jq_filter | select(.resolved == false)"
		fi
	fi

	get_all_entries | jq ".[] | $jq_filter"
}

# Get single entry by ID
get_entry() {
	local id="$1"
	local file="${ENTRIES_DIR}/${id}.json"

	if [[ -f "$file" ]]; then
		cat "$file"
	else
		echo "null"
	fi
}

# Check if entry exists
entry_exists() {
	local id="$1"
	[[ -f "${ENTRIES_DIR}/${id}.json" ]]
}

# Update entry field
update_entry_field() {
	local id="$1"
	local field="$2"
	local value="$3"
	local file="${ENTRIES_DIR}/${id}.json"

	if [[ ! -f "$file" ]]; then
		echo "Error: Entry not found: $id" >&2
		return 1
	fi

	local temp_file="${file}.tmp"
	if [[ "$field" == "resolved" ]]; then
		# Boolean fields
		jq ".${field} = $value" "$file" >"$temp_file"
	else
		# String fields (including skill_linked)
		jq ".${field} = \"$value\"" "$file" >"$temp_file"
	fi

	mv "$temp_file" "$file"
}

# Format entry for display
format_entry() {
	local entry="$1"
	local show_full="${2:-false}"

	if [[ "$show_full" == "true" ]]; then
		echo "$entry" | jq .
	else
		local id context correction
		id=$(echo "$entry" | jq -r '.id')
		correction=$(echo "$entry" | jq -r '.correction')
		context=$(echo "$entry" | jq -r '.context' | cut -c1-60)
		local agent category severity resolved
		agent=$(echo "$entry" | jq -r '.agent')
		category=$(echo "$entry" | jq -r '.category')
		severity=$(echo "$entry" | jq -r '.severity')
		resolved=$(echo "$entry" | jq -r '.resolved')

		# Status indicator
		local status_str="○"
		if [[ "$resolved" == "true" ]]; then
			status_str="✓"
		fi

		printf "[%s] %-20s %s | %s | %s | %s\n" \
			"$status_str" "$id" "$correction" "$agent" "$category" "$severity"
	fi
}

# Count entries matching criteria
count_entries() {
	local agent_filter="${1:-}"
	local category_filter="${2:-}"
	local severity_filter="${3:-}"

	get_all_entries | jq "length"
}

# Get entries grouped by field
group_by_field() {
	local field="$1"

	get_all_entries | jq "group_by(.${field}) | map({($field): .[0].${field}, count: length})"
}

# Sort entries
sort_entries() {
	local sort_field="${1:-timestamp}"
	local sort_order="${2:-desc}"

	if [[ "$sort_order" == "asc" ]]; then
		get_all_entries | jq "sort_by(.${sort_field})"
	else
		get_all_entries | jq "sort_by(.${sort_field}) | reverse"
	fi
}

# Check for jq availability
check_jq() {
	if ! command -v jq >/dev/null 2>&1; then
		echo "Error: jq is required for self-improvement command" >&2
		exit 1
	fi
}

# Validate entry structure
validate_entry() {
	local entry="$1"

	local required_fields=("id" "timestamp" "agent" "category" "severity" "correction" "context" "tags" "resolved")

	for field in "${required_fields[@]}"; do
		if ! echo "$entry" | jq -e ".${field}" >/dev/null 2>&1; then
			echo "Error: Missing required field: $field" >&2
			return 1
		fi
	done

	return 0
}

# Export entry as markdown
export_entry_markdown() {
	local entry="$1"

	local id correction context agent category severity tags skill_linked resolved
	id=$(echo "$entry" | jq -r '.id')
	correction=$(echo "$entry" | jq -r '.correction')
	context=$(echo "$entry" | jq -r '.context')
	agent=$(echo "$entry" | jq -r '.agent')
	category=$(echo "$entry" | jq -r '.category')
	severity=$(echo "$entry" | jq -r '.severity')
	tags=$(echo "$entry" | jq -r '.tags | join(", ")')
	skill_linked=$(echo "$entry" | jq -r '.skill_linked')
	resolved=$(echo "$entry" | jq -r '.resolved')

	cat <<EOF
## ${correction}

**ID:** ${id}
**Agent:** ${agent}
**Category:** ${category}
**Severity:** ${severity}
**Status:** $([ "$resolved" == "true" ] && echo "✓ Resolved" || echo "○ Open")

### Details

${context}

$([ "$tags" != "null" ] && [ -n "$tags" ] && echo "**Tags:** ${tags}
" || echo "")
$([ "$skill_linked" != "null" ] && [ -n "$skill_linked" ] && echo "**Linked Skill:** ${skill_linked}
" || echo "")
---

EOF
}

# Export entry as JSON
export_entry_json() {
	local entry="$1"
	echo "$entry" | jq .
}

# Calculate statistics
calculate_stats() {
	local all_entries
	all_entries=$(get_all_entries)

	local total_count resolved_count unresolved_count
	total_count=$(echo "$all_entries" | jq 'length')
	resolved_count=$(echo "$all_entries" | jq '[.[] | select(.resolved == true)] | length')
	unresolved_count=$((total_count - resolved_count))

	cat <<EOF
{
  "total_entries": $total_count,
  "resolved": $resolved_count,
  "unresolved": $unresolved_count,
  "by_agent": $(echo "$all_entries" | jq 'group_by(.agent) | map({agent: .[0].agent, count: length}) | sort_by(.count) | reverse'),
  "by_category": $(echo "$all_entries" | jq 'group_by(.category) | map({category: .[0].category, count: length}) | sort_by(.count) | reverse'),
  "by_severity": $(echo "$all_entries" | jq 'group_by(.severity) | map({severity: .[0].severity, count: length}) | map(select(.severity != null))')
}
EOF
}

# Pretty print statistics
print_stats() {
	local stats="$1"

	local total resolved unresolved
	total=$(echo "$stats" | jq '.total_entries')
	resolved=$(echo "$stats" | jq '.resolved')
	unresolved=$(echo "$stats" | jq '.unresolved')

	echo -e "${BOLD}Self-Improvement Statistics${RESET}"
	echo ""
	echo "Total entries: $total"
	echo "  ✓ Resolved: $resolved"
	echo "  ○ Unresolved: $unresolved"
	echo ""

	echo "By Agent:"
	echo "$stats" | jq -r '.by_agent[] | "  \(.agent): \(.count)"'
	echo ""

	echo "By Category:"
	echo "$stats" | jq -r '.by_category[] | "  \(.category): \(.count)"'
	echo ""

	echo "By Severity:"
	echo "$stats" | jq -r '.by_severity[] | select(.severity != null) | "  \(.severity): \(.count)"'
}

# Archive old entries (move to archive directory)
archive_entries() {
	local days="${1:-30}"

	init_storage
	local archive_dir="${DATA_DIR}/archive"
	mkdir -p "$archive_dir"

	local cutoff_date
	cutoff_date=$(date -d "${days} days ago" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -v-${days}d -u '+%Y-%m-%dT%H:%M:%SZ')

	local archived=0
	for file in "$ENTRIES_DIR"/*.json; do
		[[ -f "$file" ]] || continue

		local timestamp
		timestamp=$(jq -r '.timestamp' "$file" 2>/dev/null)

		# Simple date comparison (ISO8601 format sorts lexicographically)
		if [[ "$timestamp" < "$cutoff_date" ]]; then
			mv "$file" "$archive_dir/"
			((archived++))
		fi
	done

	echo "Archived $archived entries"
}

# Delete old entries permanently
delete_old_entries() {
	local days="${1:-90}"

	init_storage

	local cutoff_date
	cutoff_date=$(date -d "${days} days ago" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -v-${days}d -u '+%Y-%m-%dT%H:%M:%SZ')

	local deleted=0
	for file in "$ENTRIES_DIR"/*.json; do
		[[ -f "$file" ]] || continue

		local timestamp
		timestamp=$(jq -r '.timestamp' "$file" 2>/dev/null)

		if [[ "$timestamp" < "$cutoff_date" ]]; then
			rm "$file"
			((deleted++))
		fi
	done

	echo "Deleted $deleted entries"
}

check_jq
