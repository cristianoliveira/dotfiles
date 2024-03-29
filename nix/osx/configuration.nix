{ config, pkgs, ... }:

{
  # Referecence:
  # https://github.com/LnL7/nix-darwin/tree/master

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
    colima # container runtimes on macOS (docker)
    docker
    docker-compose
    ngrok
    ctags

    # Essential pkgs
    curl
    wget
    htop
    coreutils

    # Helper cli tools
    bitwarden-cli

    # Languages
    nodejs_20 # npm set prefix ~/.npm-global
    yarn
    python3
    go
    cargo # rust
    luarocks

    # OSX tiling window manager
    yabai
    skhd
  ];

  # Enable yabai and skhd services
  # https://github.com/LnL7/nix-darwin/blob/f0dd0838c3558b59dc3b726d8ab89f5b5e35c297/modules/services/yabai/default.nix#L44
  services.yabai = { 
    enable = true;
    enableScriptingAddition = true;
  };
  services.skhd.enable = true;

  # GUI applications via homebrew
  homebrew = {
    enable = true;

    taps = [];

    casks = [
      "alfred" # Launcher

       # Browsers
      "firefox"
      "google-chrome"
      "google-chrome-canary"
      "brave-browser"
      "finicky" # Ensure to open links in a browser/profile based on rules

      # Entertainment Apps
      "spotify"
      # "slack"
      "whatsapp"
      "telegram"

      "karabiner-elements"
      "alacritty"

      # More dev tools
      "visual-studio-code" # For pairing
      "dbeaver-community" # DB sql client
      "tunnelblick" # VPN

      # Others
      "bitwarden"
      "veracrypt"
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
      universalaccess.reduceMotion = false; # Reducing motion makes switching workspaces slow

      # define delays, keyrepeat and press and hold
      NSGlobalDomain.InitialKeyRepeat = 10;
      NSGlobalDomain.KeyRepeat = 1;
      NSGlobalDomain.ApplePressAndHoldEnabled = false;

      # set fn properly
      NSGlobalDomain."com.apple.keyboard.fnState" = true;

      # Dock configs
      dock.autohide = true;

      # Finder and file managment
      finder.AppleShowAllFiles = true;
      NSGlobalDomain.AppleShowAllFiles = true;
      finder._FXShowPosixPathInTitle = true;
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # Experimental features
  # If you used nix/osx/setup.sh to setup your system this feature is already enabled
  # via the $HOME/.config/nix/nix.conf file
  # nix = {
  #   package = pkgs.nix;
  #   settings = {
  #     "extra-experimental-features" = [ "nix-command" "flakes" ];
  #   };
  # };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
