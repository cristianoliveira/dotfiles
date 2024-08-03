{ config, pkgs, lib, ... }:
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Development environment
    git
    tmux
    zsh
    oh-my-zsh
    zsh-completions
    zsh-syntax-highlighting
    diff-so-fancy
    fzf
    ripgrep
    jq
    ngrok

    # Nvim stuff
    vim
    neovim 
    python311Packages.pynvim
    python311Packages.pip

    # My custom pkgs
    # pkgs.funzzy
    mypkgs.funzzy
    # mypkgs.ergo

    # Essential pkgs
    curl
    wget
    bc
    htop
    gcc
    gnumake

    # Languages
    nodejs_20 # npm set prefix ~/.npm-global
    python3
    python311Packages.pip
    go
    cargo #

    # GUIs
    alacritty
    bitwarden

    ## Media manipulation
    gimp

    # Data managment
    rclone
    zip
  ];
}
