# Browser routing

Check https://github.com/cristianoliveira/brouter

- Work patterns go to Chrome during local weekday hours (09:00 inclusive to 17:00 exclusive).
- Work patterns go to Brave outside that window, including weekends.
- Local/development patterns go to Chrome Canary.
- Other URLs go to Brave through the static `@default` fallback.

The external route command preserves work-first precedence during working hours. Outside that window, a work match returns Brave explicitly so the static Work rule cannot reactivate; development matches remain active. Original case-sensitive substring regex semantics are preserved, including unescaped dots: a pattern can match in a URL path or query, not only its hostname. Duplicate local patterns were removed without changing matching behavior.

The Canary executable path is macOS-specific. Change that target for a Linux installation; Brave/Chrome names resolve per platform.

## Use

Validate before installing (using your built or installed `brouter`):

```sh
brouter validate --config "$HOME/.dotfiles/nix/shared/brouter/config.toml"
brouter explain --config "$HOME/.dotfiles/nix/shared/brouter/config.toml" 'https://github.com/cristianoliveira/brouter'
```

To use this file at the default location, create a link only if no file or symlink already exists:

```sh
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/brouter"
case "$config_dir" in
  /*) ;;
  *) config_dir="$HOME/.config/brouter" ;;
esac
cfg="$config_dir/config.toml"
if [ -e "$cfg" ] || [ -L "$cfg" ]; then
  printf 'Not replacing existing configuration: %s\n' "$cfg"
else
  mkdir -p "$config_dir"
  ln -s "$HOME/.dotfiles/nix/shared/brouter/config.toml" "$cfg"
fi
```

A macOS GUI app does not inherit shell startup variables. Without a GUI-visible XDG_CONFIG_HOME it reads `~/.config/brouter/config.toml`. Keep both consumers pointed at the same file. This does not change the default browser.

The relative route-command form is `command = ["./route.py"]` and requires the brouter build with config-relative executable resolution. Place a `route.py` symlink beside the selected config symlink, pointing to this directory's mutable script; linking only `config.toml` is insufficient. Brouter invokes the executable directly, so it does not expand `~`, `$HOME`, or shell commands. Until that brouter build and colocated symlink are installed, do not switch the live command entry.

The Canary executable path is macOS-specific. Change that target for a Linux installation; do not treat this TOML as a complete cross-platform browser mapping.
