# Funzzy status experiment

One existing watcher per local project folder, shared by all its agents.
Herdr spaces are the project contexts; tabs and panes do not get separate watchers.
Multiple spaces with the same folder share one monitor. Different path aliases
or nested folders are not canonicalized or searched upward.

## Behavior

- Poll open local projects every three seconds through `fzz ctl`.
- Show the active project's state, generation, and failure count in the bottom bar.
- Notify through Herdr when a newly observed generation passes or fails, including
  background projects. Click the notification to select its space.
- Initial results and first results after a watcher restart are silent. Repeated
  observations do not repeat notifications. Offline periods keep the last observed
  generation for notification deduplication, but the indicator shows `offline`.
- Closing the last space for a folder stops monitoring it.

No watcher is started. No jobs are triggered, retried, or cancelled. No output,
commands, failure messages, or credentials are copied into notifications.
Status is polled, not an event log: short intermediate generations can be missed.
Capabilities and status are separate requests, not an atomic snapshot. This is
read-only feedback, not proof that a particular agent's edit passed checks.
Notifications are local to this mounted mod, not coordinated across app windows.

## Use

The mod needs a control-capable Funzzy CLI (v2). Desktop and terminal PATHs can
resolve different versions. The `tmux` layout explicitly sets the mod prop
`"binary": "~/.cargo/bin/fzz"` to use the local Cargo installation, not Nix's
older `fzz`. Change this prop to your v2 executable if installed elsewhere.
`~/` expands to Herdr's home directory; other executable paths are literal.
Without the prop, the mod uses `fzz` from the desktop PATH. It does not invoke a
shell or search project-local binaries.

In each project's existing `.watch.yaml` (or `.watch.yml`), configure a socket,
for example:

```yaml
on:
  socket: .tmp/funzzy/control.sock
```

Keep the project's existing jobs and other settings. Start its watcher manually
with `fzz` in a terminal. The mod uses the space's project folder as cwd, leaving
config and socket discovery to Funzzy. Custom config filenames or CLI-only socket
overrides are not supported by this experiment.

Install and reload the personal layout:

```sh
bash stow/install.sh herdr
herdr-app do layout.switch --name tmux
herdr-app status
```

`offline` means the CLI could not be started or could not query the configured
watcher. To diagnose this layout, run
`~/.cargo/bin/fzz ctl --format json capabilities` from that project. A v1 CLI on
the desktop PATH also reports `offline`, since it rejects control arguments.
`unsupported` means capabilities do not advertise schema 1 and `status`.
`error` means invalid JSON or status data. `remote` means deliberately unmonitored.
Unidentified legacy watchers can display status but do not send completion alerts.
The indicator uses text as well as color: muted for unavailable states, foreground
for running, accent for passed, and blocked color for failed.

## Verify

```sh
node --experimental-default-type=module --experimental-test-coverage --test nix/shared/herdr/mods/funzzy-status/*.test.mjs
herdr-app check "$PWD/nix/shared/herdr/mods/funzzy-status"
```

The transport/model and project monitoring logic use injected dependencies for
unit tests. Herdr's real UI is checked with `herdr-app check` and live status.
Herdr bounds each exec to 30 seconds and 8 MiB; polls for a project never overlap.

## Remove

1. Remove the `funzzy-status` block from `layouts/tmux.json`.
2. Remove `stow/herdr/.config/herdr-app/mods/funzzy-status` and its installed
   `~/.config/herdr-app/mods/funzzy-status` symlink.
3. Delete this directory and reload the layout.

No other mod imports this module. No watcher lifecycle or runtime state changes
need to be undone.
