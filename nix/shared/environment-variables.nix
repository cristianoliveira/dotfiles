{ pkgs, ... }:

{
  ## These variables are only evaluated after the user has logged in
  # So changing them will not affect the current session
  # you may need to log out and log back in
  environment.variables = rec {
    # Default editor
    EDITOR = "${pkgs.neovim}/bin/nvim";
    # Opens man pages in neovim with highlighting
    MANPAGER = "${EDITOR} +Man!";

    # Disable telemetry everywhere?? *doubt meme*
    DO_NOT_TRACK = "1";

    # Set a custom PATH
    # See https://github.com/LnL7/nix-darwin/issues/122
    # Workaround for macos because it sets the system path with higher priority
    # than nix paths this will reverse the order of the path's sections
    # PATH=$(echo $PATH | sed 's/:/\n/g' | tac | tr "\n" ":")
    PATH = builtins.concatStringsSep ":" [
      # Systemwise
      "/usr/local/bin"
      "/opt/homebrew/bin"

      # Local
      "$HOME/.dotfiles/bin"
      "$HOME/bin"
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "/nix/var/nix/profiles/default/bin"
      "/nix/var/nix/profiles/system/sw/bin"
      "/nix/var/nix/profiles/system/sw/sbin"
      "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"

      "$PATH"
    ];

    # Xcode path for command line tools
    # Make sure to install Xcode from the App Store
    # FIXME Add this to ~/.env
    # DEVELOPER_DIR="/Library/Developer/CommandLineTools"; # When installed with xcode-select --install
  };
}
