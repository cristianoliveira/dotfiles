# Herdr key bindings

Nix installs `herdr-app` and `herdr-core`. Stow links `keys.json` and the
personal `project-picker` mod into `~/.config/herdr-app`; Herdr owns settings,
layouts, sessions, and runtime state.
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
| `Ctrl-p` | Search projects under `~/work` and `~/other` |
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

## Project picker

Press `Ctrl-a`, then `Ctrl-p` (hold Ctrl for both letters if preferred).
Type a fuzzy query, use arrows or click a row, and press Enter to open it.
Escape cancels without creating a space. Plain `Ctrl-a p` still means next tab.

Discovery follows the same roots and depth as `bin/tmux-sp`: immediate child
directories of `~/work` and `~/other`, including directory symlinks. Labels are
`work/project` or `other/project`. Missing roots are skipped; unreadable roots
show a warning. Local spaces with the same canonical folder are reused;
otherwise a local space is created with one terminal tab. Remote spaces are
not reused. Unlike the tmux script, it does not create five starter windows.
Python 3, already installed by the shared developer tools, handles discovery.
Project names are passed as data, never interpolated into shell commands.

Verify changes with:

```sh
python3 -m unittest discover -s nix/shared/herdr/tests -v
node --experimental-default-type=module --test nix/shared/herdr/tests/model.test.mjs
herdr-app check ~/.config/herdr-app/mods/project-picker
herdr-app do mod.open:project-picker
herdr-app status
```

The personal mod is not a copy of Herdr's shipped picker, so app upgrades do
not replace it. Only files in this directory belong in Git; runtime state
stays outside it.

## Remaining tmux differences

Not mapped yet: last-window/session toggles and other tmux popups,
copy-mode vi selection, synchronization, pane resize/equalize, mouse toggles,
and automatic folder-based rename. Herdr has no direct equivalent in its
current command list for these workflows. Settings and core configuration
are left unchanged.

Do not bind `Ctrl-Alt-Shift-Escape`: Herdr reserves it to reset keys/layout.
Reset can move the managed symlink aside; rerun Stow after reviewing the reset
files to restore the managed bindings.
