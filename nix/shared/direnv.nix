{ pkgs, ... }: {
  programs.direnv = {
    enable = true;
    package = pkgs.direnv;
    silent = true;
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };
}
