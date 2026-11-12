# Herdr Term adoption

The `tmux` layout and existing shortcut chords now use the compatible Herdr Term
packages listed below. Source stays pinned to the released `v0.2.0` commit in
`herdr-term`; `stow/herdr/dev-mods.txt` selects compiled modules for setup.
The build/link tool does not choose a layout. Existing personal geometry, theme,
terminal bindings, settings, sessions, and unrelated modules stay unchanged.

## Active routing

Keys below follow the `Ctrl-a` prefix unless a full chord is shown.

| Key or surface | Current implementation |
| --- | --- |
| `Ctrl-b` existing-space picker | `muxcle-picker` |
| `Shift-r` navigation repeat | `muxcle-repeat` |
| `j`, `Shift-j`, `Cmd-j`, `Cmd-g` inbox | `muxcle-agent-intray` |
| `[`, `Ctrl-[` copy launcher | `muxcle-copy-mode` |
| `Shift-l` last space; `Ctrl-r` / `Tab` last tab | `muxcle-history` |
| `Shift-Left`, `Shift-Right`, `.`, `Shift-n` tab tools | `muxcle-tab-tools` |
| `-` close-spaces review | `muxcle-space-closer` |
| `Space` project-popup launcher | `muxcle-project-popup` |
| `Shift-p` listening-process review | `muxcle-port-process-picker` |
| `e` reviewed broadcast prototype | `muxcle-broadcast-prototype` |
| Existing pane footer and clock slots | `muxcle-workspace-chrome` |
| Existing machine/agent status slot | Installed native `workspace-status` |
| Existing Funzzy status slot | `muxcle-funzzy-status` |

Exactly one shown History observer and Tab Tools command host are added as
one-pixel children of the existing work column. The existing one-pixel inbox
observer slot now hosts Agent Intray. The old `tmux-compat` host remains mounted
for the retained commands and rollback. No whole layout or keymap is replaced
with a package's sample configuration.

## State, helpers, and safety changes

- History and Agent Intray use their own bounded stores. Old history/unread
  events remain untouched but are not imported. Visit two tabs/spaces before
  expecting the new last-target toggles to work. Old unread events remain
  accessible through the retained module: `herdr-app do mod.open:intray`.
- Picker still uses native ordering; this batch does not opt it into MRU or
  management. No picker config is created or overwritten.
- Copy mode opens a launcher first. **Copy snapshot** runs the bundled helper
  with installed Python 3, `hc`, and an isolated local Neovim viewer. It reads the exact reviewed terminal,
  including a remote target when selected; only explicit yank uses OSC 52.
  Neovim must supply its built-in OSC 52 clipboard helper. The viewer header
  requires Herdr's shipped `peek` mod; do not copy/install a separate `peek`.
- Project popup executes the focused local project's `.tmp/popup` only after
  explicit **Run**. That script is arbitrary user code. Closing its dialog does
  not terminate a running/kept terminal.
- Process review scans local listeners only on request using Python, `lsof` and
  `ps`. Selection is not termination. TERM and force KILL require separate review
  and confirmation; remote focus has no local fallback.
- Space close requires review and an explicit confirmation button. It can stop
  terminals and agents; queued commands do not prove completion and are not
  retried automatically.
- Broadcast remains a prototype, not transparent tmux synchronization. Opening
  it sends no input. Review 2–8 exact local terminal targets and explicitly start
  the relay. Unsupported input and context changes stop it; partial delivery is
  possible. Runtime requires Python 3 with curses, `herdr-app`, `hc` with framed
  `terminal.attach`, and Herdr's shipped `peek` module; do not copy/install `peek`.
- Funzzy keeps `~/.cargo/bin/fzz` and explicitly sets `remote: true` to preserve
  the old row's existing local/connected-remote monitoring policy. It observes
  watchers; it does not start, retry, cancel, or trigger jobs. Its new notification
  cursor starts separately, with a silent initial baseline. Native metadata
  queries and status polling occur while its block is mounted.

Deployment/build checks validate payloads and configuration, not every native
render, keyboard, remote, helper, or destructive flow. Do not test cleanup by
closing real work or killing processes. Open/cancel review launchers first.

## Deliberately retained implementations

These remain active because replacing them would lose behavior or require
additional personal configuration:

- `project-picker`: scans `~/work` and `~/other` locally and on connected machines.
  Sessionizer requires explicit absolute local and remote roots; none are
  invented and no machine/home discovery is run during migration.
- `number-spaces` / `number-agents`: expanded Git/worktree, machine, priority,
  pin/history/peek, and management controls are not supplied by numbered strips.
- `tmux-tabs`: per-space panel persistence is not provided by the custom Herdr
  Term bars. Native brand/sidebar-footer blocks remain unchanged too.
- `tmux-compat.rotate-panes` and `tmux-compat.shrink-height`: old helpers accept
  mixed terminal/mod layouts; the released standalone packages refuse mod panes.
- `image-preview` and `port-forward`: no matching replacement is supplied. A
  listening-process picker is not a port-forwarding replacement.

All old modules remain installed for rollback, even when their usual entry
point moved. Do not delete their source, assets, helpers, state, or compatibility
host merely because the new packages are installed.

## Rollback

Reverse the batch migration commit with a normal `git revert`; it restores only
that commit's reviewed keys, layout content, and selection. Resolve conflicts
instead of overwriting later personal edits. New module links/generations and
shared-state stores remain available; a revert does not delete user state.
For a single feature, restore only its action or block content from Git history.
Never copy a whole old keymap/layout over subsequent personal changes.
