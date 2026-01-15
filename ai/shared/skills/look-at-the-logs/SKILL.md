---
name: look-at-the-logs
description: Search through specific provided logs to find specific information.
---

# Look at the Logs (LAL)

Search through specific provided logs to find specific information.

## Where to find logs

If `$PWD/.logsrc` file is provided, read and use it as a primary source of logs.

The predefined places to look for logs are:
**relevant**
 - `$PWD/.tmp/logs/default/*.logs` - All will link relevant logs there.
 - `$PWD/.tmp/logs/runtime/*.logs` - Runtime logs, like when running a service.
 - `$PWD/.tmp/logs/watcher/*.logs` - Watcher logs, for tests, linting, etc.
**less relevant**
 - `/var/log/*.logs` - System logs, like when running a service. (ask for permission)
 - `/tmp/*.logs` - Temporary logs, like when running a service.

## Critical Rules

### 1. On logs format
Unless specified, logs are pure text files. There might be cases wher logs are in json format, for those cases use `jq` to search for the information.

### 2. If needed, truncate the logs, but with backups
If the logs are too big, you can truncate them, but make sure to keep a backup of the original logs. Using .bak extension is a good practice.
