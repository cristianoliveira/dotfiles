{
  description = "Nixos config flake - v1";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # OSX
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    co-pkgs.url = "github:cristianoliveira/nixpkgs/2b74288";
  };

  outputs = { self, nixpkgs, nix-darwin, co-pkgs, ... }:
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, ... }: { 
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [ 
            (final: prev: { copckgs = import co-pkgs { inherit pkgs; }; })
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
            (final: prev: { copckgs = import co-pkgs { inherit pkgs; }; })
          ];
        })

        ./osx/configuration.nix
      ];
    };

    devShells."x86_64-linux".default = import ./nix/development-environment.nix { inherit nixpkgs; };
    devShells."aarch64-darwin".default = import ./nix/development-environment.nix { inherit nixpkgs; };
  };
}
