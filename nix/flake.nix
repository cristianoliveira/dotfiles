{
  description = "Nixos config flake - v1";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # OSX
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    copkgs.url = "github:cristianoliveira/nixpkgs";

    linkman = {
      url = "github:cristianoliveira/nix-linkman";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, unstable, nix-darwin, copkgs, linkman, ... }: let
    pkgsSetup = { system, ... }: { 
      # Injects mypkgs into nixpkgs as pkgs.mypkgs
      nixpkgs = {
        config = { allowUnfree = true; };

        overlays = [ 
          (final: prev: { 
            copkgs = copkgs.packages.x86_64-linux;
            unstable = import unstable {
              inherit system;
              config = { allowUnfree = true; };
            };
          })
        ];
      };
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        pkgsSetup system

        linkman.nixosModules.${system}.linkman
        ./nixos/linkman.nix

        ./nixos/configuration.nix
      ];
    };
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";
      modules = [
        pkgsSetup system

        ./osx/configuration.nix
      ];
    };
  };
}
