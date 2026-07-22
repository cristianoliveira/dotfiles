# tmux plugin development

Notes from building copy-mode keybindings that spawn popups.
Save future-you the debugging loop below.

## Copy-mode keybindings

Copy-mode uses the `copy-mode-vi` key table. Bind with:

```
bind-key -T copy-mode-vi <key> send-keys -X <copy-command> "<shell-cmd>"
```

## Gotchas learned the hard way

### 1. `copy-pipe[-and-cancel]` runs via `run-shell` — `TMUX_PANE` is NOT set

Do not read `TMUX_PANE` inside the piped script. Pass the pane explicitly with
tmux format expansion in the keybind:

```
send-keys -X copy-pipe-and-cancel "/path/to/script.sh #{pane_id}"
```

and read it as `$1`.

### 2. Use `copy-pipe-and-cancel`, not `copy-pipe`, when the command opens a popup

Without `-and-cancel`, copy mode stays active and holds the pane, so
`tmux popup` never renders (silent failure). Every popup-triggering binding
must cancel copy mode first.

### 3. `run-shell` (and therefore `copy-pipe`) has a minimal env

`AGENT_WORKSPACE`, interactive-shell aliases, etc. are NOT inherited.
When logging from a run-shell-invoked script, default log paths to a fixed
location — do not assume the dev shell's env. Verify the actual log path
with `bash -x` redirected to a file before concluding "the script didn't run".

## Popup UX patterns

### Prefix popups (non-copy-mode)

Use `popup -E` (or `display-popup -E`) on the prefix table:

```
bind-key <key> popup -E -w 50% -h 40% -b rounded "~/.dotfiles/tmux/scripts/script.sh"
```

- `-E` blocks until popup closes — the script can `read`, run `fzf`, etc.
- `-b rounded` for visual polish.
- Scripts get full interactive terminal inside the popup.
- No `#{pane_id}` needed unless the script needs to `send-keys` back somewhere.

### Platform portability (macOS + Linux)

These tools work identically across macOS and Linux without branching:

| Need | Command | Works on both? |
|------|---------|---------------|
| PIDs on a port | `lsof -ti :PORT` | ✅ |
| Process details by PID | `ps -p PID -o comm=,args=` | ✅ |
| Interactive selection | `fzf --multi` | ✅ |

Avoid `ss`, `fuser`, `netstat` — they differ or may not exist on macOS.

- **Driving via `tmux send-keys "C-a ["` does NOT enter copy mode reliably.**
  Use `tmux copy-mode -t <pane>` to enter, then `send-keys` the rest.
- **`source-file` does not unbind removed keys.** Add an explicit
  `unbind-key -T copy-mode-vi <key>` when removing a binding.
- To see if `copy-pipe-and-cancel` runs *any* command, bind a throwaway key to
  `echo X > /tmp/canary` and press it manually. CLI-driven keypresses often
  don't reproduce the issue.
