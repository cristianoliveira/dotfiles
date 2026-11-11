# dotfiles

My "dotfiles" is a reproducible development environment for NixOS and macOS. 

Different systems, same i3 like develepor experience.

I try to keep the DX of both systems as close as possible, as well as, the overall UI/UX. I'd say they are 90% similar.

# System Details

```bash
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖           me@localhost
          ▜███▙       ▜███▙  ▟███▛           ----------------------
           ▜███▙       ▜███▙▟███▛            OS: NixOS 24.05.20 (Uakari) x86_64
            ▜███▙       ▜██████▛             Host: LENOVO 21MECTO1WW
     ▟█████████████████▙ ▜████▛     ▟▙       Kernel: 6.6.59
    ▟███████████████████▙ ▜███▙    ▟██▙      Uptime: 45 mins
           ▄▄▄▄▖           ▜███▙  ▟███▛      Packages: 1098 (nix-system), 1053 (nix-user)
          ▟███▛             ▜██▛ ▟███▛       Shell: zsh 5.9
         ▟███▛               ▜▛ ▟███▛        Resolution: 1920x1200, 1920x1080
▟███████████▛                  ▟██████████▙  WM: sway
▜██████████▛                  ▟███████████▛  Terminal: tmux
      ▟███▛ ▟▙               ▟███▛           CPU: AMD Ryzen 7 PRO 8840HS
     ▟███▛ ▟██▙             ▟███▛            GPU: AMD ATI Phoenix3 
    ▟███▛  ▜███▙           ▝▀▀▀▀             Memory: 3397MiB / 27711MiB
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛
           ▟██████▙       ▜███▙
          ▟███▛▜███▙       ▜███▙
         ▟███▛  ▜███▙       ▜███▙
         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘
--------------------

                    c.'          me@localhost
                 ,xNMM.          ---------------------------------
               .OMMMMo           OS: macOS 14.3.1 23D60 arm64
               lMM"              Host: Mac14,9
     .;loddo:.  .olloddol;.      Kernel: 23.3.0
   cKMMMMMMMMMMNWMMMMMMMMMM0:    Uptime: 4 days, 22 hours, 41 mins
 .KMMMMMMMMMMMMMMMMMMMMMMMWd.    Packages: 256 (brew), 469 (nix-system)
 XMMMMMMMMMMMMMMMMMMMMMMMX.      Shell: bash 5.2.26
;MMMMMMMMMMMMMMMMMMMMMMMM:       Resolution: 1920x1080 @ FHDHz, 3024x1964
:MMMMMMMMMMMMMMMMMMMMMMMM:       DE: Aqua
.MMMMMMMMMMMMMMMMMMMMMMMMX.      WM: AeroSpace
 kMMMMMMMMMMMMMMMMMMMMMMMMWd.    Terminal: tmux
 'XMMMMMMMMMMMMMMMMMMMMMMMMMMk   CPU: Apple M2 Pro
  'XMMMMMMMMMMMMMMMMMMMMMMMMK.   GPU: Apple M2 Pro
    kMMMMMMMMMMMMMMMMMMMMMMd     Memory: 20678MiB / 32768MiB
     ;KMMMMMMMWXXWMMMMMMMk.
       "cooc*"    "*coo'"
```

### Look and feel

![systemprint](https://github.com/cristianoliveira/dotfiles/assets/3959744/808ecffc-f4b3-426a-ab1c-fa589ee702fd)

https://github.com/user-attachments/assets/48642cc7-3a5f-4037-863a-eaa493a7b10c

# What do I use?

  - Nix (for package and system management)
  - Neovim
  - Tmux
  - ZSH (oh-my-zsh)
  - Terminal: Alacritty
  - WM: AeroSpace (osx) / sway (linux)
  - Launcher: alfred (osx) / ulauncher (linux)
  - Others: Check `nix/*` folder

### I work mostly with

  - Typescript & Javascript (React & Node, et all)
  - HTML & CSS
  - Rust
  - Golang

  A bunch of 

  - Bash

  And a bit of

  - Ruby
  - Python

## Installing

Check detailed explanation in `nix/README.md` doc, but you will need nix

### Prerequisites

 - [Nix for packaging](https://nixos.org/learn/)
 - Generate your [ssh key and add to your github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
 - In short `ssh-keygen -t ed25519 -C "your_email@example.com"` and add the key to your github account.

In short:
```bash
curl https://raw.githubusercontent.com/cristianoliveira/dotfiles/main/install.sh | bash -s - osx
# or
curl https://raw.githubusercontent.com/cristianoliveira/dotfiles/main/install.sh | bash -s - linux
```

Or step by step

```bash
git clone --recurse-submodules git@github.com:cristianoliveira/dotfiles.git ~/.dotfiles

cd ~/.dotfiles

# For linux users
make linux
# or
make osx

# Updating and setup
make setup
```

### Herdr development checkout

`herdr-term/` is a Git submodule pointing to the Muxcle repository. Dotfiles pin its exact commit; update that pointer deliberately after committing and pushing changes in the submodule.

For an existing dotfiles checkout:

```bash
git submodule update --init --recursive -- herdr-term
```

This fetches source only. It does not build mods, replace existing configuration, or activate development links. Build/watch and deployment wiring are separate steps; existing Herdr mods remain unchanged.

### OS change workflow

Once you make a change in `nix/*` run `nix/rebuild.sh` and follow the steps.
(Optional) Use the watcher with `fzz -t nix` which will auto-rebuild each time something changes.

### Automated Nix updates

[Update Nix packages](.github/workflows/update-nix.yml) runs every Monday at
06:17 UTC. It updates all flake inputs, evaluates Linux and macOS system
derivations, and opens or refreshes one PR containing only `nix/flake.lock`.
No lockfile changes means no new PR. Evaluation failures stop publication;
an older PR may still exist and does not represent the failed update.
This does not upgrade the release branches declared in `nix/flake.nix`,
update Homebrew packages, or deploy changes to a machine.

After this workflow reaches the default branch:

1. In **Settings → Actions → General → Workflow permissions**, enable
   **Allow GitHub Actions to create and approve pull requests**.
2. Run it from **Actions → Update Nix packages → Run workflow**, or use
   `gh workflow run update-nix.yml`.
3. Review the PR and rebuild both systems before merging. Evaluation is not
   a full build or runtime test.

Merging is manual by default. Auto-merge is possible: enable **Allow auto-merge**
in repository settings, configure required build checks in branch protection,
then run `gh pr merge <PR-number> --auto --squash`. With no required checks,
a mergeable PR can merge immediately. PRs created with `GITHUB_TOKEN` do not
trigger ordinary `pull_request` workflows; use a scoped GitHub App token if
adding that CI flow. Direct commits are also possible, but skip PR review and
remain subject to branch protection. A conflict-free update is not proof that
packages work.

GitHub can disable scheduled workflows after 60 days of inactivity in public
repositories. Re-enable the workflow in Actions if this happens.

### Mappings

Key modifier (MOD): `Command` (osx) and `Alt` (Nixos) 

 - `ctrl + space`: open app launcher
 - `MOD + number`: move to workspace
 - `MOD + shift + number`: send the current window to a workspace
 - `MOD + ctrl + f`: move the current window to fullscreen (over other windows).
 - `MOD + ctrl + h/j/k/l`: move focus to a window depending on the current focused window.
 - `MOD + shift + h/j/k/l`: move the window to a new position.
 - `MOD + ctrl + enter`: Open terminal or, if there is a terminal opened, shift focus to.
