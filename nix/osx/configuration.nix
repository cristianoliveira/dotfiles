{ pkgs, ... }:

{
  # Referecence:
  # https://github.com/LnL7/nix-darwin/tree/master
  imports =
    [ 
      ./developer-tools.nix
      ./applications.nix
      ./window-manager.nix

      # Shared between linux and darwin
      ../shared/developer-tools.nix
      ../shared/direnv.nix

      # Others
      ./streaming.nix
      # TODO: this is temporary, move this to a shell.nix somehow
      # ./mobile-dev.nix
    ];

  # Allow proprietary pkgs for apps like ngrok
  nixpkgs.config.allowUnfree = true;

  # Enable yabai and skhd services
  # https://github.com/LnL7/nix-darwin/blob/f0dd0838c3558b59dc3b726d8ab89f5b5e35c297/modules/services/yabai/default.nix#L44
  services = {
    yabai = { 
      enable = false;
      enableScriptingAddition = true;
    };
    skhd.enable = false;
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
        export EDITOR='nvim'
      '';

      # Oh-my-zsh configuration
      promptInit = ''
        plugins=(git vi-mode history-substring-search)
        source $ZSH/oh-my-zsh.sh
      '';

      loginShellInit = ''
        # See https://github.com/LnL7/nix-darwin/issues/122
        # Workaround for macos because it sets the system path with higher priority
        # than nix paths this will reverse the order of the path's sections
        # PATH=$(echo $PATH | sed 's/:/\n/g' | tac | tr "\n" ":")
        nixpaths=(
          /nix/var/nix/profiles/default/bin
          /nix/var/nix/profiles/system/sw/bin
          /nix/var/nix/profiles/system/sw/sbin
          /run/current-system/sw/bin
          $HOME/.nix-profile/bin
        )
        for nixpath in $nixpaths[@]; do
          PATH="$nixpath:$PATH"
        done
        typeset -U path
      '';
    };
  };

  system = {
    primaryUser = "cristianoliveira";

    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToControl = true;

    defaults = {
      # Keyboard settings
      # Enable full keyboard access for all controls
      # (e.g. enable Tab in modal dialogs)
      # define delays, keyrepeat and press and hold
      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        _HIHideMenuBar = true;

        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        ApplePressAndHoldEnabled = false;
        # set fn properly
        "com.apple.keyboard.fnState" = true;

        # Finder default
        AppleShowAllFiles = true;
      };

      # NOTE: This is not working, but it should
      # ERROR: defaults[41922:398520] Could not write domain com.apple.universalaccess; exiting
      # universalaccess.reduceMotion = true;

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
  nix.enable = true;
  nix.package = pkgs.nix;
  ids.gids.nixbld = 350;
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
