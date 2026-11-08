# Herdr key bindings

Nix installs `herdr-app` and `herdr-core`. Stow links `keys.json` and the
personal mods, Solarized Dark theme, and `tmux` layout into
`~/.config/herdr-app`; Herdr owns settings, sessions, runtime state, and other
layouts.
The install hook creates a real app directory so Stow cannot link the whole
mutable directory into this repository.

`make nix` runs Stow after a successful system rebuild. To install only Herdr
without rebuilding or processing other Stow packages, run from the repository root:

```sh
bash stow/install.sh herdr
```

If Stow reports an existing `keys.json`, quit Herdr first, review the file,
and back it up outside the app directory before retrying. A running app can
recreate a missing keys file before Stow links it. Do not use `--adopt`, which
would replace the repository's config.
Keys reload live. Check `herdr-app status` and `~/.config/herdr-app/keys.error`
if an edit does not take effect. Edit the source file in this directory.

## Theme

The `tmux` layout selects `solarized-dark` explicitly, independent of system
light/dark appearance. Its palette lives in `themes/solarized-dark.json` and
Stow links it into Herdr. Restarts and repeated installs retain this choice;
Herdr's theme picker can still change it intentionally.

The install hook keeps `themes/` a real directory so Herdr can add other themes
without writing them into this repository. Settings and existing themes stay
untouched. After installing into a running app, select the layout again to
reload it after the palette is linked:

```sh
herdr-app do layout.switch --name tmux
herdr-app status
python3 -m unittest discover -s nix/shared/herdr/tests -p test_install.py -v
```

## Sidebar status

The `tmux` layout uses `number-spaces` and `number-agents`, personal clones
of Herdr 0.1.13's sidebar mods. Compact rows show status through the number's
color instead of a dot or spinner. Working numbers have a subtle pulsing
background; other states stay static. The selected space keeps its row highlight.
Expanded sidebar views keep the original controls.

The `pane-footer` mod shows each pane's program, folder, and native `branch`
value below its terminal. Branches are pane-specific, not taken from the space.
The shared bottom bar uses `tmux-status` for computer and agent counts on the
left, with local time and date on the right (`HH:MM ddd DD-Mon-YY`, matching
`tmux.conf`). The clock checks local time each second but redraws only when the
displayed minute changes.

The bottom bar uses `tmux-tabs`, a personal clone of Herdr 0.1.13's `tabs` mod
without minimize, maximize, or window-close buttons. Tab creation, selection,
closing, reordering, and panel toggles remain available. Time/date stays at the
far right of this bottom bar, not in the sidebar.

The layout mounts `tmux-tabs` twice: `mode: "tabs"` for the tab strip, and
`mode: "panels"` for the new-tab `+` button and Files/Changes. This puts the
isolated Funzzy watcher status before `+` and the panel buttons, with time/date
last. The right-side blocks use compact widths; Files is icon-only in the split
controls. Without a mode, `tmux-tabs` retains its combined tab-and-panel rendering.

These clones do not receive upstream mod updates. Compare them with Herdr's
shipped `spaces`, `agents`, and `tabs` mods when upgrading.

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
| `Space` | Toggle project-local `.tmp/popup` terminal (`tmux` layout) |
| `Shift-p` | Toggle local listening-port process picker (`tmux` layout) |
| `e` | Toggle prototype broadcast-input mode for current-tab panes (`tmux` layout) |
| `[` | Open keyboard-only copy mode for the focused terminal (`tmux` layout) |
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
Type a fuzzy query, use ↑/↓ or Ctrl-j/Ctrl-k to move down/up, or click a row.
Press Enter to open it. Ctrl-h/Ctrl-l keep their search-field behavior.
Escape cancels without creating a space. Plain `Ctrl-a p` still means next tab.

Discovery follows the same roots and depth as `bin/tmux-sp`: immediate child
directories of `~/work` and `~/other`, including directory symlinks but excluding
names that start with `.` (hidden directories and hidden symlinks). Labels are
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

Press `Ctrl-a`, then `Ctrl-b` to open `tmux-picker`, a personal clone of
Herdr 0.1.13's space/tab picker. Type to search, use ↑/↓ or Ctrl-j/Ctrl-k to
move down/up, Enter to switch, or Escape to cancel. Ctrl-d still closes the
selected tab. Spaces are ordered by their most recently focused tab, and tabs
within each space are most-recent-first. Quiet spaces remain visible; unvisited
items retain their source order. New-tab and new-space actions stay at the end.

`tmux-compat` records focus order while the `tmux` layout is active, whether
navigation comes from a picker, sidebar, or shortcut. History builds as you
navigate and persists in Herdr's own `shared.json` under
`tmux-compat.recent-tabs`; closed tabs/spaces are removed. Existing last-space
and last-tab shortcuts keep their separate two-item history.

Compare this clone with the shipped `picker` on Herdr upgrades; it does not
receive upstream updates automatically.

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

### Project-local terminal popup

Press `Ctrl-a`, then Space to execute the focused local terminal's
`.tmp/popup` script in a temporary terminal overlay. Press the same shortcut
again, click Close in the header, or click outside the dialog to dismiss it.
Escape stays available to the program inside, for example Vim or fzf.
When the program exits, the overlay closes automatically.

Create `.tmp/popup` in a trusted project with an executable shebang, for example:

```sh
#!/usr/bin/env bash
exec zsh
```

Then run `chmod +x .tmp/popup` from that project. Missing or non-executable
scripts produce a notice without creating a terminal. This deliberately
executes project code; do not use it in an untrusted checkout. No command
runs automatically when you visit a project. Remote spaces are rejected,
not silently redirected to the local machine.

The launcher passes paths as argv data, including whitespace and punctuation.
It creates a separate, labelled core terminal without parent-agent notes,
`keep`, or project tab adoption. Closing the popup releases only that owned
terminal; unrelated terminals are never targets. If you explicitly adopt it
with core keep, cleanup leaves it running. Script exit and duplicate cleanup
are harmless. Orderly cleanup is best-effort on app shutdown; an app crash
can leave a core terminal alive. `hc ls --all` lists core terminals for recovery.
Very short commands may finish before there is a useful screen to display.
Remote popups remain unsupported.

### Kill-port terminal popup

Press `Ctrl-a`, then `Shift-p` to open the existing
`~/.dotfiles/tmux/scripts/kill-port.sh` picker in a 50% x 40% terminal overlay.
It lists local listening TCP processes. Type a port, PID, or process name to
filter; Tab selects multiple rows; **Enter immediately sends SIGKILL (`kill -9`)
to the selected processes**. There is no extra confirmation. Review the rows
before pressing Enter. Escape cancels; no selection means no kill.

This reuses the tmux helper without invoking tmux. It requires executable
script permissions plus `bash`, `lsof`, and `fzf` on the app's PATH. Missing
prerequisites produce a notice before a terminal is created. It never runs a
project-provided kill script and refuses remote spaces, so a remote project
cannot silently target this machine's processes.

Either popup shortcut dismisses an already-active compat terminal popup.
Close and outside click stop only the picker terminal, not listed processes.
Once a selection is confirmed, closing the overlay cannot undo the kill.

### Keyboard copy mode

Press `Ctrl-a`, then `[` to open a read-only Neovim snapshot of the focused
terminal's screen and up to 10,000 scrollback lines. Keeping Ctrl held for `[`
also works (`Ctrl-a Ctrl-[`). Use `hjkl`, `gg`/`G`,
Ctrl-u/Ctrl-d and `/` search to navigate. Use `v` for character selection, `V`
for whole lines, or Ctrl-v for a rectangle. Press `y` to copy to the local
system clipboard; `q` or Escape in normal mode exits. Escape in visual mode
first cancels the selection. The prefix shortcut also dismisses the viewer.

Scrollback capture has a three-second limit. If it times out, copy mode makes
one screen-only request with its own three-second limit. The status bar says
`COPY MODE (screen only)` and a snapshot notice identifies the reduced capture. If both requests time out,
the popup reports failure rather than opening an empty editor.

This is a frozen text snapshot, not native selection in the original pane.
The source program keeps running and receives none of the viewer's keys.
If it does not open, `herdr-app status` reports key/layout/mod errors; terminal
capture errors appear inside the viewer popup. A key chord that is not bound
can fail without a startup error.
Remote terminal addresses are read through `hc`; the viewer itself runs locally.
Colors, images and terminal soft-wrap metadata are not preserved. The initial
cursor starts at the bottom of the snapshot.

Requires Python 3, `hc`, Neovim with `vim.ui.clipboard.osc52`, and Herdr's
`clipboard_write` permission (enabled by default). No clipboard helper is
required. Snapshots are capped at 8 MiB and clipboard selections at 1 MiB.
The isolated editor disables user plugins, local configuration, modelines,
swap/backup/undo files and editing. Snapshots use a private temporary directory
and are removed on normal exit or handled termination; a forced kill/crash can
leave temporary files behind. It is not an editor sandbox.

### Broadcast input mode (prototype)

Press `Ctrl-a`, then lowercase `e` to open a single-line input indicator
in the top-left corner (240 × 32 px), without dimming the window.
Wait for **BROADCAST ON · Esc exits**, then type there. Each keystroke goes to every
terminal pane captured from the current tab. **Enter submits in every target**;
Ctrl+C is also broadcast. Escape exits instead of reaching the targets.
The same shortcut, Escape, or clicking outside dismisses the relay. There is
no title bar or Close button; the indicator is the focused input surface.

If an already-running app still shows the old wide dialog after updating the
mod, dismiss it and switch away from the layout and back to recreate its mod:

```sh
herdr-app do layout.switch --name terminals
herdr-app do layout.switch --name tmux
```

This is an input proxy, not transparent synchronization while typing directly
into an ordinary pane. It uses the existing core framed-stream API through one
session-bound `hc connect` process. No native app/core patch, persistent service,
network listener, or global keyboard permissions are needed. Typed content is
not displayed or logged by the relay; normal target-program history still applies.

The first version supports 2–8 live local terminal panes, ordinary UTF-8 text,
punctuation, basic controls, arrows, Backspace, Delete, Home/End and Page Up/Down.
SSH sessions inside local panes can receive input too; spaces hosted on a remote
core are refused. Other tabs, detached agents, mod panes and popup terminals are
not targets. The target list stays frozen; duplicate terminal references receive
input only once. It requires Python 3 with curses, plus `hc` and `herdr-app`.

Use it with shell-like input first. **Alt combinations, paste, function keys,
and advanced TUI/Kitty keyboard modes are not supported.** Bracketed paste or
Alt input starts with Escape and exits; Ctrl+V stops the mode. IME composition
has not been tested. Input typed before READY is ignored. Clicking a normal pane
leaves the broadcast input surface; it does not install a keyboard hook there.

Before each queued batch, the relay checks the original space/tab, pane
membership, target liveness and process identity. Changed context, failed
checks, stream loss, an unsupported key, or a full bounded queue stops further
delivery without retry. An in-flight batch can already have reached some panes;
there is no rollback. Opening another dialog also stops delivery. Reopen the
mode to review a new target set. Test on harmless commands before real work.

Check it with:

```sh
node --experimental-default-type=module --test nix/shared/herdr/tests/*.test.mjs
herdr-app check ~/.config/herdr-app/mods/tmux-compat
herdr-app do tmux-compat.last-space
herdr-app do tmux-compat.last-tab
herdr-app do tmux-compat.rename-from-folder
herdr-app do tmux-compat.repeat
herdr-app do tmux-compat.close-spaces
herdr-app do tmux-compat.popup
herdr-app do tmux-compat.kill-port
herdr-app do tmux-compat.broadcast
```

## Remaining tmux differences

Not mapped yet: transparent repeat key tables, other tmux popups,
native in-pane copy-mode selection (the keyboard snapshot viewer is available),
transparent pane synchronization, pane resize/equalize, and mouse
toggles. Herdr has no direct equivalent in its current command list for
these workflows. Settings and core configuration
are left unchanged.

Do not bind `Ctrl-Alt-Shift-Escape`: Herdr reserves it to reset keys/layout.
Reset can move the managed symlink aside; rerun Stow after reviewing the reset
files to restore the managed bindings.
