{ pkgs, ... }:

{
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
      interactiveShellInit = ''
        export NIX_ENV=1
      '';

      # Oh-my-zsh configuration
      promptInit = ''
        plugins=(git vi-mode history-substring-search)
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
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

  system.primaryUser = "cristianoliveira";

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
