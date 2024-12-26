{ pkgs, ... }:

{
  ## These variables are only evaluated after the user has logged in
  # So changing them will not affect the current session
  # you may need to log out and log back in
  environment.sessionVariables = rec {
    # Default editor
    EDITOR = "${pkgs.neovim}/bin/nvim";
    # Opens man pages in neovim with highlighting
    MANPAGER = "${EDITOR} +Man!";
  };
}
