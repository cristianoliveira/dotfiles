{ pkgs, ... }: {
  programs.direnv = {
    enable = true;
    package = pkgs.direnv;
    # FIXME: this is not working used the env var above
    # See: https://github.com/direnv/direnv/issues/68#issuecomment-2812015043
    silent = true; 
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };
}
