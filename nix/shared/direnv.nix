{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    direnv
    nix-direnv
  ];

  programs.direnv = {
    package = pkgs.direnv;
    silent = true;
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };
}
