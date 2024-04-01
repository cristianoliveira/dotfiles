{
  description = "Nixos config flake - v1";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    co-pkgs = {
      url = "github:cristianoliveira/nixpkgs/main";
    };
  };

  outputs = { self, nixpkgs, co-pkgs, ... }:
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, ... }: { 
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [ 
            (final: prev: { mypkgs = import co-pkgs { inherit pkgs; }; })
          ];
        })
        ./nixos/configuration.nix
      ];
    };
  };
}
