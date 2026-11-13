# Herdr configuration

Herdr Term owns the compiled terminal-workflow packages. Its source is the pinned
`herdr-term` submodule; `stow/herdr/dev-mods.txt` selects the installed modules.
Change reusable behavior there instead of copying implementations into dotfiles.
`stow/herdr/native-views.json` selects installed native views and existing view-state
directories. It creates links, not runtime copies or copied preference stores.

This directory owns personal configuration:

- `keys.json`: shortcut chords and actions.
- `layouts/tmux.json`: composition, theme, geometry, and required shown hosts.
- `themes/solarized-dark.json`: the personal palette.
- `mods/`: local capabilities not yet supplied by the selected packages/native views.

Herdr owns settings, sessions, shared state, and unrelated layouts. Native modules
and assets are reused from the installed app, not copied into this repository.

## Install

Nix installs Herdr and its runtime tools. From the dotfiles root, install only
this configuration with:

```sh
bash stow/install.sh herdr
```

The hook initializes the pinned source, builds complete selected generations,
and installs repository-managed links. It refuses foreign development targets
and preserves conflicting personal config in a backup. Do not use Stow `--adopt`.
Mutable app-home containers remain real directories.

Edit the source keys/layout here; their installed links reload live. A package's
History observer or command host must remain shown in the chosen layout. New
History and Agent Intray stores are independent of previous mod state; do not
replace `shared.json`. Review launchers do not execute, capture, close, signal,
or broadcast until their explicit action is chosen.

## Development and checks

Use the source repository's tests for packaged behavior. The dotfiles checks
verify configuration installation, ownership, conflict refusal, and last-good
links after failed builds:

```sh
make herdr-test
node herdr-term/scripts/dev-loop.mjs status --mod muxcle-picker --app-home "$HOME/.config/herdr-app"
```

The source recipes describe package prerequisites and supported behavior. Build
and configuration checks do not prove every native interactive flow. Git history
is the source backup; do not maintain copied runtime implementations as fallback.
