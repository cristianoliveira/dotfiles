---
name: logcli-logs
description: Query and analyze logs from Grafana Loki using logcli. Use when the user mentions Loki, Grafana logs, logcli, or LogQL. Triggers on phrases like "query loki", "loki logs", "grafana logs", "use logcli", "LogQL query", or when explicitly asked to search logs using Loki/Grafana infrastructure.
---

# Logcli Log Query Skill

Query logs from Loki using `logcli`. Assumes `logcli` is installed and configured (LOKI_ADDR, LOKI_USERNAME, LOKI_PASSWORD env vars if needed).

## Quick Reference

```bash
# Basic label query
logcli query '{app="myapp"}'

# Text search within logs
logcli query '{app="myapp"} |= "error"'

# Regex search
logcli query '{app="myapp"} |~ "error|warning"'

# Tail live logs
logcli query '{app="myapp"}' --tail

# Time range (last 1 hour)
logcli query '{app="myapp"}' --since=1h

# Specific time range
logcli query '{app="myapp"}' --from="2024-01-01T00:00:00Z" --to="2024-01-01T01:00:00Z"

# Limit results
logcli query '{app="myapp"}' --limit=100

# Output format (default, raw, jsonl)
logcli query '{app="myapp"}' --output=jsonl
```

## Label Discovery

Before querying, discover available labels:

```bash
# List all label names
logcli labels

# List values for a specific label
logcli labels app
logcli labels namespace
logcli labels pod
```

## LogQL Query Patterns

### Label Matchers
- `{label="value"}` - exact match
- `{label=~"regex.*"}` - regex match
- `{label!="value"}` - not equal
- `{label!~"regex"}` - regex not match

### Line Filters (after label selector)
- `|= "text"` - contains
- `!= "text"` - does not contain
- `|~ "regex"` - regex match
- `!~ "regex"` - regex not match

### JSON Parsing
```bash
# Parse JSON and filter by field
logcli query '{app="api"} | json | level="error"'

# Extract specific field
logcli query '{app="api"} | json | line_format "{{.message}}"'
```

## Common Workflows

### Find errors in the last hour
```bash
logcli query '{app="myapp"} |= "error"' --since=1h --limit=500
```

### Tail logs for debugging
```bash
logcli query '{app="myapp"}' --tail
```

### Search across multiple apps
```bash
logcli query '{app=~"api|worker|scheduler"} |= "exception"' --since=30m
```

### Count errors (use instant query)
```bash
logcli instant-query 'count_over_time({app="myapp"} |= "error" [1h])'
```

## Important Flags

| Flag | Description |
|------|-------------|
| `--since=1h` | Relative time (1h, 30m, 2d) |
| `--from` / `--to` | Absolute timestamps |
| `--limit=N` | Max log lines to return |
| `--tail` | Stream logs in real-time |
| `--output=raw` | Raw log lines only |
| `--output=jsonl` | JSON lines format |
| `--quiet` | Suppress query stats |
| `--forward` | Show oldest first |

## Troubleshooting

If `logcli` fails:
1. Check `LOKI_ADDR` is set: `echo $LOKI_ADDR`
2. Test connection: `logcli labels`
3. Verify auth if needed: check `LOKI_USERNAME`/`LOKI_PASSWORD`
