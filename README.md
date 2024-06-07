# dotfiles

My "dotfiles" now fully set up my development environment for Nixos and OSX

![systemprint](https://github.com/cristianoliveira/dotfiles/assets/3959744/808ecffc-f4b3-426a-ab1c-fa589ee702fd)

# Setup

I try to keep the DX of both systems as close as possible. As well as the overall UI/UX. I'd say they are 90% similar.

```bash

          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖            me@localhost
          ▜███▙       ▜███▙  ▟███▛            ----------------------
           ▜███▙       ▜███▙▟███▛             OS: NixOS 23.11.20240322.56528ee (Tapir) x86_64
            ▜███▙       ▜██████▛              Host: Dell Inc. 06YPRH
     ▟█████████████████▙ ▜████▛     ▟▙        Kernel: 6.1.82
    ▟███████████████████▙ ▜███▙    ▟██▙       Uptime: 20 hours, 41 mins
           ▄▄▄▄▖           ▜███▙  ▟███▛       Packages: 1138 (nix-system), 511 (nix-user)
          ▟███▛             ▜██▛ ▟███▛        Shell: bash 5.2.15
         ▟███▛               ▜▛ ▟███▛         Resolution: 1366x768, 1920x1080
▟███████████▛                  ▟██████████▙   WM: sway
▜██████████▛                  ▟███████████▛   Theme: Adwaita [GTK3]
      ▟███▛ ▟▙               ▟███▛            Icons: Adwaita [GTK3]
     ▟███▛ ▟██▙             ▟███▛             Terminal: tmux
    ▟███▛  ▜███▙           ▝▀▀▀▀              CPU: Intel i5-4210U (4) @ 2.700GHz
    ▜██▛    ▜███▙ ▜██████████████████▛        GPU: Intel Haswell-ULT
     ▜▛     ▟████▙ ▜████████████████▛         Memory: 3140MiB / 7861MiB
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
.MMMMMMMMMMMMMMMMMMMMMMMMX.      WM: yabai
 kMMMMMMMMMMMMMMMMMMMMMMMMWd.    Terminal: tmux
 'XMMMMMMMMMMMMMMMMMMMMMMMMMMk   CPU: Apple M2 Pro
  'XMMMMMMMMMMMMMMMMMMMMMMMMK.   GPU: Apple M2 Pro
    kMMMMMMMMMMMMMMMMMMMMMMd     Memory: 20678MiB / 32768MiB
     ;KMMMMMMMWXXWMMMMMMMk.
       "cooc*"    "*coo'"
```

# What do I use?

  - NIX (for package and system management)
  - Neovim
  - Tmux
  - ZSH (oh-my-zsh)
  - Terminal: Alacritty
  - WM: yabai (osx) / sway (linux)
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

### Prerequisites

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
git clone git@github.com:cristianoliveira/dotfiles.git ~/.dotfiles

cd ~/.dotfiles

# For linux users
make linux
# or
make osx

# Updating and setup
make setup
```
