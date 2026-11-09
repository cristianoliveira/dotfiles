# Funzzy status experiment

One existing watcher per machine and project folder, shared by all its agents.
Herdr spaces are the project contexts; tabs and panes do not get separate watchers.
Multiple spaces on the same machine with the same folder share one monitor. Equal
paths on different machines stay independent. Different path aliases or nested
folders are not canonicalized or searched upward.

## Behavior

- Poll open local and connected remote projects every three seconds through
  `fzz ctl`. Remote commands use Herdr Core's existing machine transport; this mod
  does not open another SSH connection or socket tunnel.
- Show the active project's state, generation, failure count, and any locally
  located watcher tab in the bottom bar. Click a located local indicator to focus
  its watcher pane.
- Locate watchers through Herdr's foreground process metadata, not terminal title
  text or the shell's startup command. Rename an unnamed matching tab to `watcher`
  once; custom tab names stay unchanged.
- Notify through Herdr when a newly observed generation passes or fails, including
  background projects. Click the notification to focus the located watcher pane,
  or select the project space when no unique watcher pane is available.
- Initial results and first results after a watcher restart are silent. Repeated
  observations do not repeat notifications. Offline periods keep the last observed
  generation for notification deduplication, but the indicator shows `offline`.
- Closing the last space for a machine and folder stops monitoring it.

No watcher is started. No jobs are triggered, retried, or cancelled. No output,
commands, failure messages, or credentials are copied into notifications.
Status is polled, not an event log: short intermediate generations can be missed.
Capabilities and status are separate requests, not an atomic snapshot. This is
read-only feedback, not proof that a particular agent's edit passed checks.
Notifications are local to this mounted mod, not coordinated across app windows.

Location discovery queries only panes in local project spaces with `hc get`.
Remote status remains read-only and does not claim a local watcher-pane location.
It recognizes bare `fzz`/`funzzy` or explicit `fzz watch` invocations (absolute
executable paths work). Flag-prefixed implicit watch commands are not inferred.
Foreground cwd must match the project folder exactly. This is a location hint,
not proof of socket ownership: a watcher using an alternate config in the same
folder can still match. With multiple matching panes, the indicator shows the
count, no tab is automatically renamed, and no arbitrary pane is selected.
Background/detached watchers without a matching foreground pane remain unlocated.

## Use

The mod needs a control-capable Funzzy CLI (v2) on each monitored machine.
Desktop, terminal, and remote PATHs can resolve different versions. The `tmux`
layout explicitly sets the local mod prop `"binary": "~/.cargo/bin/fzz"` to use
the local Cargo installation, not Nix's older `fzz`. Change this prop to your
local v2 executable if installed elsewhere. `~/` expands to Herdr's local home
directory; other executable paths are literal.

Remote projects deliberately do not reuse that local absolute path. They use
`fzz` from the remote machine's non-interactive PATH by default. Set the optional
`"remoteBinary"` prop to an executable name or absolute path that exists on remote
machines when needed. `~/` is not expanded remotely because Herdr executes argv
directly without a shell. The mod does not search project-local binaries.

In each project's existing `.watch.yaml` (or `.watch.yml`), configure a socket,
for example:

```yaml
on:
  socket: .tmp/funzzy/control.sock
```

Keep the project's existing jobs and other settings. Start its watcher manually
with `fzz` in a terminal on that project machine. The mod uses the space's project
folder and machine as Herdr exec context, leaving config and socket discovery to
the Funzzy installed there. It never starts a watcher. Custom config filenames or
CLI-only socket overrides are not supported by this experiment.

Install and reload the personal layout:

```sh
bash stow/install.sh herdr
herdr-app do layout.switch --name main
herdr-app do layout.switch --name tmux
herdr-app status
```

`offline` means the selected machine was unavailable, the CLI could not be
started there, or it could not query the configured watcher. To diagnose a local
project, run `~/.cargo/bin/fzz ctl --format json capabilities` from that project.
For a remote project, run the equivalent command through Herdr Core:

```sh
hc exec --on MACHINE --cwd FOLDER -- fzz ctl --format json capabilities
```

A v1 CLI also reports `offline`, since it rejects control arguments.
`unsupported` means capabilities do not advertise schema 1 and `status`.
`error` means invalid JSON or status data. Unidentified legacy watchers can
display status but do not send completion alerts.
The indicator uses text as well as color: theme blue (`ansi4`) for running,
green (`ansi2`) for passed, red (`ansi1`) for failed, and muted for other states.

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

No other mod imports this module. No watcher lifecycle changes need to be undone.
The `watcher` tab name persists in Herdr; clear it manually with
`herdr-app do tab.rename --id TAB_ID --name ''` if you want its automatic name back.
