## Nixos and nix packaging

If you are in NixOs you are all set and good to go.

If you are on OSX or another linux distro you may need to check this:
https://nixos.org/download/

TL;DR;

### macOs (OSX)
```bash
sh <(curl -L https://nixos.org/nix/install) 
```

### Linux
```
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Make sure to enable Flakes: https://nixos.wiki/wiki/flakes

### Building the system

```bash
nix/rebuild.sh
```

## After installation setup

Most configs are setup using Nix, but there are programs like 
alacritty, tmux, fonts, etc, they need configurations in `$HOME/.config`.
For those, run the following scripts:

Linux
```bash
$HOME/.dotfiles/nix/nixos/setup.sh
```

MacOS
```bash
$HOME/.dotfiles/nix/osx/setup.sh
```

Eventually I'll port them to Nix once I figure how to

### Troubleshooting

To debug nix flakes do:
```bash
nix repl
```

Inside the repl load the flake file
```nix
:lf .
```

Inspect the `inputs` and `outputs`
```nix
inputs.<TAB>
```
It will expand the object

See more in: 
https://archive.ph/kEgp1
