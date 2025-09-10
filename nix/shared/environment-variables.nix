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

    # Path
    PATH = builtins.concatStringsSep ":" [
      # Systemwise
      "/usr/local/bin"
      "/opt/homebrew/bin"

      # Local
      "$HOME/.npm-global/bin"
      "$HOME/.dotfiles/bin"
      "$HOME/bin"
      "$HOME/.local/bin"
    ];
  };
}
