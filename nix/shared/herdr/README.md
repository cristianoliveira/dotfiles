# Herdr key bindings

Nix installs `herdr-app` and `herdr-core`. Stow links `keys.json` and the
personal mods and `tmux` layout into `~/.config/herdr-app`; Herdr owns settings,
sessions, runtime state, and other layouts.
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
not tmux's repeat key table: repeat the prefix for each action, or explicitly
enter the bounded navigation repeat mode below.

| After Ctrl-a | Action |
|---|---|
| `c` | New tab in the focused terminal's folder |
| `n` / `p` | Previous / next tab (same order as your tmux config) |
| `Ctrl-p` | Search projects under `~/work` and `~/other` |
| `Ctrl-b` | Search existing spaces and tabs |
| `Shift-l` (uppercase `L`) | Toggle last two spaces (`tmux` layout) |
| `Ctrl-r` / `Tab` | Toggle last two tabs in this space (`tmux` layout) |
| `1`–`9` | Select tab |
| `,` | Rename tab with a prompt |
| `Shift-n` (uppercase `N`) | Rename tab from focused terminal folder (`tmux` layout) |
| `Shift-r` (uppercase `R`) | Enter bounded navigation repeat mode (`tmux` layout) |
| `-` | Select multiple spaces to close, with confirmation (`tmux` layout) |
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

## Existing-space picker

Press `Ctrl-a`, then `Ctrl-b` to open Herdr's shipped space/tab picker, the
closest match to your tmux session switcher. Type to search, use arrows and
Enter to switch, or Escape to cancel. Quiet spaces can be folded under
“earlier”; searching includes them. The shipped picker also offers new-tab
and new-space actions, unlike tmux's existing-session-only list.

## Tmux compatibility layer

`mods/tmux-compat` owns missing tmux behavior. It is independent of
`project-picker`, which only discovers and opens projects. Native Herdr
commands remain direct key bindings; do not wrap features that already exist.

Enable the personal layout once after installation:

```sh
herdr-app do layout.switch --name tmux
```

This layout is based on Herdr 0.1.13's main layout, with a one-pixel,
non-focusable compat block added. Herdr requires a mounted mod to observe
space changes and receive commands. The stock layouts do not mount it, so
the shortcut only works in the `tmux` layout (or a personal layout with the
same block). Switching to it preserves spaces, tabs, and running terminals.
The layout structure is pinned; shipped mods still receive app updates.

Press `Ctrl-a`, then uppercase `L` to switch back to the previous space.
Press it again to toggle back. History observes space changes from any
source, including sidebar clicks and both pickers, and is stored under the
`tmux-compat.space-history` key in Herdr's own `shared.json`. Closed spaces
are removed; with no previous space, it shows a notice and changes nothing.
Tab changes do not change space history. Remote spaces use their full ids.
History is not tracked while the compat block is unmounted.

Press `Ctrl-a`, then `Ctrl-r` or `Tab` to toggle between the last two tabs
visited in the current space. Each space has independent history under
`tmux-compat.tab-history`. Switching spaces preserves their tab histories;
closed tabs and spaces are pruned. With no previous tab, selection stays
unchanged and a notice explains why. Inactive spaces do not record unseen
tab selections.

Press `Ctrl-a`, then uppercase `N` to rename the current tab to the basename
of the focused terminal’s working directory, matching your tmux mapping.
This uses the focused pane, not the space’s original project folder. Names
are passed directly to Herdr, without shell execution. With a mod focused or
an unknown terminal cwd, it shows a notice and leaves the tab name unchanged.
This supports Unix paths, including remote Unix terminals. `Ctrl-a ,` still
opens the normal rename prompt.

### Navigation repeat mode

Press `Ctrl-a`, release Ctrl, then uppercase `R`. A visible popup takes the
keyboard. Until it closes, use `n` / `p` for previous / next tab and
`h/j/k/l` (or `Ctrl-h/j/k/l`) to focus panes. Each supported key renews the
1.5-second inactivity timeout. Escape, the Exit button, or clicking outside
ends the mode. Unrecognized keys close it without running or sending them;
press the key again to type normally. Existing app shortcuts may still run.

This is an explicit navigation mode, not a transparent emulation of tmux's
`bind -r` table. Normal typing outside the popup is unchanged. Splits,
terminal creation, resizing, and destructive actions are not repeatable.
The pure repeat controller owns timeout state; the separate repeat view
adapts it to Herdr. It remains part of `tmux-compat`, not the project picker.

### Close multiple spaces

Press `Ctrl-a`, then `-` for a multi-select space list, matching your tmux
session-kill picker. Nothing is selected by default. Filter by name, machine
or folder; arrows move the cursor, and Tab/Ctrl+Space or clicking a row toggles
selection. Filtering keeps selections hidden by the query. Enter or Review
opens a separate confirmation listing every selected space, its machine,
and tab count. No terminals end during selection or review.

Only **Ctrl+Enter** or the red **Close spaces** button confirms closure.
Plain Enter on the review screen does not confirm. Back returns to selection;
Cancel or Escape closes the dialog without ending terminals. Closing a space
ends all its terminals, including remote ones, and cannot be undone.

Before dispatch, the controller rechecks the reviewed ids, names, machines,
tab identities and pane counts. If these changed, nothing is dispatched and
you must review again. New unselected spaces are never included. A confirmed
batch is sent once as explicit native `space.close` requests; names never
become commands. Native failures, such as an unavailable remote machine,
can cause partial completion: this is not an atomic batch and there is no
success claim or automatic retry. The native app reports command errors.

Check it with:

```sh
node --experimental-default-type=module --test nix/shared/herdr/tests/*.test.mjs
herdr-app check ~/.config/herdr-app/mods/tmux-compat
herdr-app do tmux-compat.last-space
herdr-app do tmux-compat.last-tab
herdr-app do tmux-compat.rename-from-folder
herdr-app do tmux-compat.repeat
herdr-app do tmux-compat.close-spaces
```

## Remaining tmux differences

Not mapped yet: transparent repeat key tables, other tmux popups,
copy-mode vi selection, synchronization, pane resize/equalize, and mouse
toggles. Herdr has no direct equivalent in its current command list for
these workflows. Settings and core configuration
are left unchanged.

Do not bind `Ctrl-Alt-Shift-Escape`: Herdr reserves it to reset keys/layout.
Reset can move the managed symlink aside; rerun Stow after reviewing the reset
files to restore the managed bindings.
