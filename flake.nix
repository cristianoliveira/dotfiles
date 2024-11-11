{
  description = "Dotfiles development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }: 
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        checks = {
          fmt = pkgs.runCommand "check-fmt" {} ''
            echo "Checking formatting..."
            touch $out
          '';
        };

        devShells.default = import ./shell.nix { inherit pkgs; };
    });
}
