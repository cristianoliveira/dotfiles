# Jira CLI Command Reference

## Installation & Configuration

```bash
# Install jira-cli (macOS with Homebrew)
brew install jira-cli

# Initialize configuration
jira init

# Check authentication
jira me

# List available projects
jira project list
```

## Issue Creation Command

Basic syntax:
```bash
jira issue create [flags]
```

### Required Flags
- `-p, --project string`: Project key (e.g., WEBAPP, PROJ)
- `-s, --summary string`: Issue summary/title
- `-t, --type string`: Issue type (Task, Bug, Story, etc.)

### Optional Flags
- `-b, --body string`: Issue description (supports multiline with $'text\\nmore')
- `-y, --priority string`: Priority (High, Medium, Low, Critical, etc.)
- `-l, --label stringArray`: Labels (repeat for multiple: `-l bug -l mobile`)
- `-C, --component stringArray`: Components (repeat for multiple)
- `-a, --assignee string`: Assignee username/email
- `-r, --reporter string`: Reporter username/email
- `-P, --parent string`: Parent issue key for linking
- `-e, --original-estimate string`: Original estimate (e.g., "2d", "4h")
- `--fix-version stringArray`: Fix versions
- `--affects-version stringArray`: Affects versions
- `--custom stringToString`: Custom fields (e.g., `--custom story-points=3`)

### Template Options
- `--template string`: Path to file containing description (use `-` for stdin)
- `--no-input`: Disable prompt for non-required fields
- `--web`: Open in browser after creation
- `--raw`: Output JSON instead of human-readable format

## Examples

### Basic Task Creation
```bash
jira issue create -p WEBAPP -t Task -s "Fix login button" -b "Description here"
```

### With Priority and Labels
```bash
jira issue create -p PROJ -t Bug -s "Mobile rendering issue" \
  -y High -l bug -l mobile -l frontend \
  -b $'# Description\n\nBug description...'
```

### Using Template File
```bash
# Create template file
echo "# Description" > desc.md
echo "More details..." >> desc.md

# Use template
jira issue create -p WEBAPP -t Task -s "Title" --template desc.md
```

### With Parent Link (Sub-task or Epic Child)
```bash
jira issue create -p WEBAPP -t Sub-task -s "Sub-task title" \
  -P WEBAPP-123 -b "Description"
```

### Multiple Components
```bash
jira issue create -p WEBAPP -t Story -s "New feature" \
  -C frontend -C backend -C api \
  -a username@example.com
```

## Common Field Values

### Issue Types
- `Task`: Standard work item
- `Bug`: Defect or issue
- `Story`: User story
- `Epic`: Large body of work
- `Sub-task`: Child of another issue

### Priority Levels
- `Highest`
- `High`
- `Medium`
- `Low`
- `Lowest`

## Environment Variables

- `JIRA_CONFIG_FILE`: Custom config file path
- `JIRA_PROJECT`: Default project key

## Tips

- Use `$'text\\nmore'` syntax for multiline descriptions in bash
- Pipe description from stdin: `echo "Description" | jira issue create -s "Title" -t Task`
- Combine `--template -` with pipe for complex descriptions
- Use `--no-input` for non-interactive scripts
- Check `jira issue create --help` for latest options