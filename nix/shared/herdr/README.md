# Herdr key bindings

Nix installs `herdr-app` and `herdr-core`. Stow links only `keys.json` into
`~/.config/herdr-app`; Herdr owns settings, layouts, sessions, and runtime state.
The install hook creates a real app directory so Stow cannot link the whole
mutable directory into this repository.

From the repository root, run:

```sh
bash stow/install.sh herdr
```

If Stow reports an existing `keys.json`, review it and move it aside before
retrying. Do not use `--adopt`, which would replace the repository's config.
Keys reload live. Check `herdr-app status` and `~/.config/herdr-app/keys.error`
if an edit does not take effect. Edit the source file in this directory.

## Tmux equivalents

Press `Ctrl-a`, release it, then press the second key. Herdr uses chords,
not tmux's repeat key table: repeat the prefix for each action.

| After Ctrl-a | Action |
|---|---|
| `c` | New tab in the focused terminal's folder |
| `n` / `p` | Previous / next tab (same order as your tmux config) |
| `1`–`9` | Select tab |
| `,` | Rename tab with a prompt |
| `w` / `_` | Split down |
| `v` / `\|` | Split right |
| `Ctrl-h/j/k/l` | Focus pane left/down/up/right |
| `Ctrl-f` / `z` | Toggle pane zoom |
| `?` | Key help |
| `:` | Herdr command palette, not a tmux command line |
| `Ctrl-a` | Send literal Ctrl-a to the terminal |

Single `Ctrl-a` is now a prefix, not shell start-of-line. Double it for
start-of-line (or to pass one prefix to tmux inside Herdr). Herdr owns the
outer prefix; tmux's F12 nested-routing script is not integrated.

`Alt-1`–`Alt-9` select spaces (roughly tmux sessions); on macOS these may
intercept Option characters. `Cmd-n` / `Ctrl-Shift-n` create a space.
Common macOS editing, window, clipboard, and pane shortcuts remain available;
Linux clipboard/search and new-tab/split shortcuts are also included.
This file replaces defaults rather than merging them; it is a selected shared
keymap, not a full copy of either platform's stock keymap.

Not mapped yet: last-window/session toggles, tmux session picker and popups,
copy-mode vi selection, synchronization, pane resize/equalize, mouse toggles,
and automatic folder-based rename. Herdr has no direct equivalent in its
current command list for these workflows. Settings and core configuration
are left unchanged.

Do not bind `Ctrl-Alt-Shift-Escape`: Herdr reserves it to reset keys/layout.
Reset can move the managed symlink aside; rerun Stow after reviewing the reset
files to restore the managed bindings.
