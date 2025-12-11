{
  description = "Nixos config flake - v1";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # OSX
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # NUR - Nix User Repository
    nixpkgsnur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    copkgs.url = "github:cristianoliveira/nixpkgs";

    linkman = {
      url = "github:cristianoliveira/nix-linkman/537ac2d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs,
    unstable,
    nix-darwin,
    copkgs,
    linkman,
    nixpkgsnur,
    ...
  }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        (_: {
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [
            (final: prev: {
              copkgs = copkgs.packages.x86_64-linux;
              unstable = import unstable {
                inherit system;
                config = { allowUnfree = true; };
              };
              # Nightly packages namespace - access via pkgs.nightly.codex
              nightly = (import ./nightly-pkgs.nix) prev;
            })

            nixpkgsnur.overlays.default
            (import ./overlays/wrapped-pkgs.nix)
          ];
        })
        linkman.nixosModules.${system}.linkman
        ./nixos/linkman.nix

        ./nixos/configuration.nix
      ];
    };
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";
      modules = [
        (_: {
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [
            (final: prev: {
              copkgs = copkgs.packages.aarch64-darwin;
              unstable = import unstable {
                inherit system;
                config = { allowUnfree = true; };
              };
              # Nightly packages namespace - access via pkgs.nightly.codex
              nightly = (import ./nightly-pkgs.nix) prev;
            })

            nixpkgsnur.overlays.default
            (import ./overlays/wrapped-pkgs.nix)
          ];
        })

        ./osx/configuration.nix
      ];
    };
  };
}
