{ pkgs, ... }: let
  primaryUser = "cristianoliveira";
in {
  # Referecence:
  # https://github.com/LnL7/nix-darwin/tree/master
  imports =
    [ 
      # System builtin settings
      ./macos-settings.nix

      # Applications settigs
      ./developer-tools.nix
      ./applications.nix
      ./applications-shortcuts.nix
      ./global-shortcuts.nix
      ./window-manager.nix
      ./virtualization.nix

      # Shared between linux and darwin
      ../shared/sysadmin-tools.nix
      ../shared/developer-tools.nix
      ../shared/direnv.nix
      ../shared/environment-variables.nix

      # Others
      ./streaming.nix
      # TODO: this is temporary, move this to a shell.nix somehow
      # ./mobile-dev.nix
    ];

  # Allow proprietary pkgs for apps like ngrok
  nixpkgs.config.allowUnfree = true;
  
  services.openssh.enable = true;

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

      # TODO: move npm config to a singular place
      interactiveShellInit = ''
        export NIX_ENV=1

        ${pkgs.nodejs_22}/bin/npm set prefix $HOME/.npm-global
      '';

      # Oh-my-zsh configuration
      promptInit = ''
        plugins=(git vi-mode history-substring-search)
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
        source $ZSH/oh-my-zsh.sh
      '';

      loginShellInit = ''
        typeset -U path
      '';
    };
  };

  # User configuration
  system.primaryUser = primaryUser;
  environment.etc."sudoers.d/darwin-rebuild".text = ''
    ${primaryUser} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';

  # Auto upgrade nix package and the daemon service.
  nix = {
    enable = true;
    package = pkgs.nix;
    settings = {
      trusted-users = [ "root" primaryUser ];
      allowed-users = [ "*" ];
      auto-optimise-store = false;
      build-users-group = "nixbld";
      require-sigs = true;
      sandbox = false;
      sandbox-fallback = false;
      extra-sandbox-paths = [ ];
      extra-experimental-features = [ "nix-command" "flakes" ];
    };
  };
  ids.gids.nixbld = 350;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
