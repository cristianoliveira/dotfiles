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

## Debugging copy-mode bindings

- **Driving via `tmux send-keys "C-a ["` does NOT enter copy mode reliably.**
  Use `tmux copy-mode -t <pane>` to enter, then `send-keys` the rest.
- **`source-file` does not unbind removed keys.** Add an explicit
  `unbind-key -T copy-mode-vi <key>` when removing a binding.
- To see if `copy-pipe-and-cancel` runs *any* command, bind a throwaway key to
  `echo X > /tmp/canary` and press it manually. CLI-driven keypresses often
  don't reproduce the issue.
