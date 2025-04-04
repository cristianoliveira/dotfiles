{
  description = "Nixos config flake - v1";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # OSX
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    copkgs.url = "github:cristianoliveira/nixpkgs";
  };

  outputs = { nixpkgs, unstable, nix-darwin, copkgs, ... }:
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (_: { 
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [ 
            (final: prev: { 
              copkgs = copkgs.packages.x86_64-linux;
              unstable = unstable.legacyPackages.x86_64-linux;
            })
          ];
        })
        ./nixos/configuration.nix
      ];
    };
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        (_: { 
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [ 
            (final: prev: {
              copkgs = copkgs.packages.aarch64-darwin;
              unstable = unstable.legacyPackages.aarch64-darwin;
            })
          ];
        })

        ./osx/configuration.nix
      ];
    };
  };
}
