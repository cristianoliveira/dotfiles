{
  description = "Nixos config flake - v1";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # OSX
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    co-pkgs = {
      url = "github:cristianoliveira/nixpkgs/develop";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, co-pkgs, ... }:
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
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ config, pkgs, ... }: { 
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [ 
            (final: prev: { mypkgs = import co-pkgs { inherit pkgs; }; })
          ];
        })

        ./osx/configuration.nix
      ];
    };
  };
}
