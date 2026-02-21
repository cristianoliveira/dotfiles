#!/usr/bin/env bash
# self-improvement add - Add new feedback entry

# Source shared utilities if not already loaded
if [[ -z "${_SELF_IMPROVEMENT_UTILS_LOADED:-}" ]]; then
	HELPERS_DIR="${HELPERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
	source "${HELPERS_DIR}/self-improvement-utils.sh"
fi

cmd_add_usage() {
	cat <<EOF
${SCRIPT_NAME} add - Add a new self-improvement feedback entry

USAGE:
  ${SCRIPT_NAME} add [options]

OPTIONS:
  -i, --interactive        Interactive guided prompt mode
  --correction TEXT        One-line summary of correction (required)
  --context TEXT           Detailed explanation (from -i or stdin if not provided)
  --context-file FILE      Load context from file
  --agent AGENT            Agent type (required, see --list-agents)
  --category CATEGORY      Category of improvement (required, see --list-categories)
  --severity LEVEL         Severity level: high|medium|low (default: medium)
  --tags TAG1,TAG2         Comma-separated tags (optional)
  --session-id ID          Optional session identifier
  --help                   Show this help message

INPUT MODES:

1. Quick Capture (CLI Arguments):
   ${SCRIPT_NAME} add --correction "Fixed bug X" \\
     --context "Details here" \\
     --agent task-worker --category git --severity high

2. Interactive Mode:
   ${SCRIPT_NAME} add -i

3. From Stdin (context):
   echo "Detailed context..." | ${SCRIPT_NAME} add \\
     --correction "Summary" \\
     --agent task-worker --category git

4. From File (context):
   ${SCRIPT_NAME} add --correction "Summary" \\
     --context-file details.md \\
     --agent task-worker --category git

VALID AGENTS:
  task-worker, janitor, leader, orchestrator, code-review, safety-check, general

VALID CATEGORIES:
  file-operations, git, safety, code-quality, workflow, performance, 
  documentation, testing, integration, other

EXAMPLES:

Quick capture:
  $ ${SCRIPT_NAME} add \\
    --correction "Fixed git rebase safety check" \\
    --context "Added validation for protected branches" \\
    --agent task-worker --category git --severity high \\
    --tags "git,safety"

Interactive:
  $ ${SCRIPT_NAME} add -i

From stdin:
  $ cat error_log.txt | ${SCRIPT_NAME} add \\
    --correction "Fixed parsing error" \\
    --agent janitor --category file-operations

From file:
  $ ${SCRIPT_NAME} add \\
    --correction "Refactored commit logic" \\
    --context-file detailed_explanation.md \\
    --agent task-worker --category git --severity medium

List valid agents:
  $ ${SCRIPT_NAME} add --list-agents

List valid categories:
  $ ${SCRIPT_NAME} add --list-categories
EOF
}

# Parse arguments for add command
cmd_add() {
	local interactive=false
	local correction=""
	local context=""
	local context_file=""
	local agent=""
	local category=""
	local severity="medium"
	local tags=""
	local session_id=""
	local stdin_available=false

	# Check if stdin has data
	if [[ ! -t 0 ]]; then
		stdin_available=true
	fi

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-i | --interactive)
			interactive=true
			shift
			;;
		--correction)
			correction="$2"
			shift 2
			;;
		--context)
			context="$2"
			shift 2
			;;
		--context-file)
			context_file="$2"
			shift 2
			;;
		--agent)
			agent="$2"
			shift 2
			;;
		--category)
			category="$2"
			shift 2
			;;
		--severity)
			severity="$2"
			shift 2
			;;
		--tags)
			tags="$2"
			shift 2
			;;
		--session-id)
			session_id="$2"
			shift 2
			;;
		--list-agents)
			echo "Valid agents:"
			for a in "${VALID_AGENTS[@]}"; do
				echo "  - $a"
			done
			exit 0
			;;
		--list-categories)
			echo "Valid categories:"
			for c in "${VALID_CATEGORIES[@]}"; do
				echo "  - $c"
			done
			exit 0
			;;
		--help | -h)
			cmd_add_usage
			exit 0
			;;
		*)
			echo "Error: Unknown option '$1'" >&2
			cmd_add_usage >&2
			exit 1
			;;
		esac
	done

	# Interactive mode
	if [[ "$interactive" == true ]]; then
		add_interactive
		return
	fi

	# Validate required fields
	if [[ -z "$correction" ]]; then
		echo "Error: --correction is required" >&2
		cmd_add_usage >&2
		exit 1
	fi

	if [[ -z "$agent" ]]; then
		echo "Error: --agent is required (see --list-agents)" >&2
		exit 1
	fi

	if [[ -z "$category" ]]; then
		echo "Error: --category is required (see --list-categories)" >&2
		exit 1
	fi

	# Validate agent
	if ! array_contains "$agent" "${VALID_AGENTS[@]}"; then
		echo "Error: Invalid agent '$agent'. Valid options: ${VALID_AGENTS[*]}" >&2
		exit 1
	fi

	# Validate category
	if ! array_contains "$category" "${VALID_CATEGORIES[@]}"; then
		echo "Error: Invalid category '$category'. Valid options: ${VALID_CATEGORIES[*]}" >&2
		exit 1
	fi

	# Validate severity
	if ! array_contains "$severity" "${VALID_SEVERITY[@]}"; then
		echo "Error: Invalid severity '$severity'. Valid options: ${VALID_SEVERITY[*]}" >&2
		exit 1
	fi

	# Load context from stdin, file, or argument
	if [[ -n "$context_file" ]]; then
		if [[ ! -f "$context_file" ]]; then
			echo "Error: Context file not found: $context_file" >&2
			exit 1
		fi
		context=$(cat "$context_file")
	elif [[ -z "$context" ]] && [[ "$stdin_available" == true ]]; then
		context=$(cat)
	elif [[ -z "$context" ]]; then
		echo "Warning: No context provided. Use --context, --context-file, or pipe from stdin." >&2
		context="(No detailed context provided)"
	fi

	# Create entry
	add_entry "$correction" "$context" "$agent" "$category" "$severity" "$tags" "$session_id"
}

# Interactive mode for adding feedback
add_interactive() {
	echo -e "${BOLD}Self-Improvement Feedback Entry${RESET}"
	echo ""

	local correction=""
	local context=""
	local agent=""
	local category=""
	local severity="medium"
	local tags=""
	local session_id=""

	# Correction (required)
	echo -e "${CYAN}What did you correct or learn?${RESET}"
	echo "Enter a one-line summary (REQUIRED):"
	read -r correction
	if [[ -z "$correction" ]]; then
		echo "Error: Correction summary is required" >&2
		exit 1
	fi

	# Context (optional)
	echo ""
	echo -e "${CYAN}Detailed explanation${RESET}"
	echo "Enter detailed context (press Enter twice to finish, or leave blank):"
	local context_lines=""
	while true; do
		read -r line
		if [[ -z "$line" ]]; then
			if [[ -z "$context_lines" ]]; then
				break
			fi
			context_lines="${context_lines}${line}"
			break
		fi
		if [[ -z "$context_lines" ]]; then
			context_lines="$line"
		else
			context_lines="${context_lines}
${line}"
		fi
	done
	context="${context_lines:-(No detailed context provided)}"

	# Agent (required)
	echo ""
	echo -e "${CYAN}Which agent captured this?${RESET}"
	echo "Valid options: ${VALID_AGENTS[*]}"
	read -r agent
	while ! array_contains "$agent" "${VALID_AGENTS[@]}"; do
		echo "Invalid agent. Valid options: ${VALID_AGENTS[*]}"
		read -r agent
	done

	# Category (required)
	echo ""
	echo -e "${CYAN}What category?${RESET}"
	echo "Valid options: ${VALID_CATEGORIES[*]}"
	read -r category
	while ! array_contains "$category" "${VALID_CATEGORIES[@]}"; do
		echo "Invalid category. Valid options: ${VALID_CATEGORIES[*]}"
		read -r category
	done

	# Severity (optional, default: medium)
	echo ""
	echo -e "${CYAN}Severity level?${RESET}"
	echo "Options: high, medium, low (default: medium)"
	read -r severity_input
	if [[ -n "$severity_input" ]]; then
		if array_contains "$severity_input" "${VALID_SEVERITY[@]}"; then
			severity="$severity_input"
		else
			echo "Invalid severity, using default: medium"
		fi
	fi

	# Tags (optional)
	echo ""
	echo -e "${CYAN}Tags (comma-separated, optional)?${RESET}"
	read -r tags

	# Session ID (optional)
	echo ""
	echo -e "${CYAN}Session ID (optional)?${RESET}"
	read -r session_id

	# Summary
	echo ""
	echo -e "${BOLD}Feedback Summary:${RESET}"
	echo "  Correction: $correction"
	echo "  Context: ${context:0:50}..."
	echo "  Agent: $agent"
	echo "  Category: $category"
	echo "  Severity: $severity"
	[[ -n "$tags" ]] && echo "  Tags: $tags"
	[[ -n "$session_id" ]] && echo "  Session ID: $session_id"
	echo ""

	read -p "Save this feedback? (y/n) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		add_entry "$correction" "$context" "$agent" "$category" "$severity" "$tags" "$session_id"
	else
		echo "Feedback entry cancelled."
	fi
}

# Create feedback entry and save to storage
add_entry() {
	local correction="$1"
	local context="$2"
	local agent="$3"
	local category="$4"
	local severity="$5"
	local tags="$6"
	local session_id="$7"

	init_storage

	# Generate ID based on current timestamp (ISO8601 without separators)
	local id
	id=$(date -u '+%Y%m%dT%H%M%SZ')

	# Handle potential ID collision
	local counter=0
	while [[ -f "${ENTRIES_DIR}/${id}.json" ]]; do
		counter=$((counter + 1))
		id=$(date -u '+%Y%m%dT%H%M%SZ')_${counter}
	done

	# Build JSON entry
	local timestamp
	timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

	local tags_json="[]"
	if [[ -n "$tags" ]]; then
		# Convert comma-separated tags to JSON array
		tags_json=$(echo "$tags" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R . | jq -s .)
	fi

	local entry
	entry=$(
		cat <<ENTRY
{
  "id": "$id",
  "timestamp": "$timestamp",
  "agent": "$agent",
  "category": "$category",
  "severity": "$severity",
  "correction": "$correction",
  "context": $(echo -n "$context" | jq -Rs .),
  "tags": $tags_json,
  "resolved": false,
  "skill_linked": null,
  "session_id": $([ -n "$session_id" ] && echo "\"$session_id\"" || echo "null")
}
ENTRY
	)

	# Save entry
	echo "$entry" >"${ENTRIES_DIR}/${id}.json"

	# Update index
	update_index "add" "$id" "$timestamp" "$agent" "$category" "$severity" "$correction"

	# Output result
	echo -e "${GREEN}✓ Feedback entry saved${RESET}"
	echo "  ID: ${CYAN}${id}${RESET}"
	echo "  Correction: $correction"
	echo ""
	echo "View with: ${CYAN}${SCRIPT_NAME} show $id${RESET}"
}

# Update index for faster lookups
update_index() {
	local action="$1"
	local id="$2"
	local timestamp="$3"
	local agent="$4"
	local category="$5"
	local severity="$6"
	local correction="$7"

	if [[ ! -f "$INDEX_FILE" ]]; then
		init_storage
	fi

	if [[ "$action" == "add" ]]; then
		# Add to index
		local index
		index=$(cat "$INDEX_FILE")
		index=$(echo "$index" | jq ". += [{\"id\": \"$id\", \"timestamp\": \"$timestamp\", \"agent\": \"$agent\", \"category\": \"$category\", \"severity\": \"$severity\", \"correction\": \"${correction//\"/\\\"}\"}]")
		echo "$index" >"$INDEX_FILE"
	fi
}
