{ config, pkgs, ... }:

{
  # Allow proprietary pkgs for apps like ngrok
  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Development environment
    vim
    neovim 
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
    funzzy
    docker
    docker-compose
    ngrok

    # Essential pkgs
    curl
    wget
    htop
    coreutils

    # Languages
    nodejs_20 # npm set prefix ~/.npm-global
    yarn
    python3
    go
    cargo # rust
    luarocks
  ];

  # GUI applications via homebrew
  homebrew = {
    enable = true;

    casks = [
      "alfred"

      "firefox"
      "google-chrome"
      "google-chrome-canary"
      "brave-browser"
      "finicky" # Ensure to open links in a browser/profile based on rules

      "spotify"

      # "slack"
      "whatsapp"
      "telegram"

      "karabiner-elements"
      "alacritty"
      # "dbeaver-community"
      #
      # "visual-studio-code"
      # "tunnelblick"
    ];
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    gnupg.agent.enable = true;
    zsh = {
      enable = true;
      interactiveShellInit = ''
        autoload -U +X compinit && compinit
        export NIX_ENV=1
        export PATH=$HOME/.npm-global/bin:/usr/local/bin:$PATH
        '';
    };
  };

  system = {
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToControl = true;

    defaults = {
      # Keyboard settings
      # Enable full keyboard access for all controls
      # (e.g. enable Tab in modal dialogs)
      NSGlobalDomain.AppleKeyboardUIMode = 3;

      # define delays, keyrepeat and press and hold
      NSGlobalDomain.InitialKeyRepeat = 10;
      NSGlobalDomain.KeyRepeat = 1;
      NSGlobalDomain.ApplePressAndHoldEnabled = false;

      # set fn properly
      NSGlobalDomain."com.apple.keyboard.fnState" = true;
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix = {
    package = pkgs.nix;
    settings = {
      "extra-experimental-features" = [ "nix-command" "flakes" ];
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
