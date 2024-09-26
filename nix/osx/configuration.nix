{ pkgs, ... }:

{
  # Referecence:
  # https://github.com/LnL7/nix-darwin/tree/master
  imports =
    [ 
      ./developer-tools.nix

      # Shared between linux and darwin
      ../shared/developer-tools.nix
      ../shared/direnv.nix
      ./streaming.nix
    ];

  # Allow proprietary pkgs for apps like ngrok
  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Other tools (GUI)
    alacritty 
    bitwarden-cli

    # OSX tiling window manager
    yabai
    skhd
  ];

  # Enable yabai and skhd services
  # https://github.com/LnL7/nix-darwin/blob/f0dd0838c3558b59dc3b726d8ab89f5b5e35c297/modules/services/yabai/default.nix#L44
  services = {
    yabai = { 
      enable = true;
      enableScriptingAddition = true;
    };
    skhd.enable = true;
  };

  # GUI applications via homebrew
  homebrew = {
    enable = true;

    taps = [];

    casks = [
      "alfred" # Launcher

       # Browsers
      "firefox"
      "google-chrome"
      # "google-chrome-canary"
      "brave-browser"
      "finicky" # Ensure to open links in a browser/profile based on rules

      # Entertainment Apps
      "spotify"
      # "slack"
      "whatsapp"
      "telegram"

      "karabiner-elements"

      # Others
      "bitwarden"
      "veracrypt"
      "mullvadvpn"
      "tunnelblick" # VPN
    ];
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    gnupg.agent.enable = true;
    zsh = {
      enable = true;
      variables = {
        ZSH = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
        ZSH_THEME = "clean";
        DISABLE_AUTO_UPDATE = "true";
      };
      interactiveShellInit = ''
        export NIX_ENV=1
        export PATH=$HOME/.npm-global/bin:$PATH
      '';

      # Oh-my-zsh configuration
      promptInit = ''
        plugins=(git vi-mode history-substring-search)
        source $ZSH/oh-my-zsh.sh
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
      NSGlobalDomain = {
        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        ApplePressAndHoldEnabled = false;
        # set fn properly
        "com.apple.keyboard.fnState" = true;

        # Finder default
        AppleShowAllFiles = true;
      };

      # Dock configs
      dock.autohide = true;

      # Finder and file managment
      finder = {
        AppleShowAllFiles = true;
        _FXShowPosixPathInTitle = true;
      };
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
