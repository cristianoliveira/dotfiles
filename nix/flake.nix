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
  };

  outputs = {
    nixpkgs,
    unstable,
    nix-darwin,
    copkgs,
    nixpkgsnur,
    ...
  }:
  let
    systems = [ "x86_64-linux" "aarch64-darwin" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        nvim = pkgs.mkShell {
          packages = [
            pkgs.neovim
            pkgs.stylua
            pkgs.lua51Packages.luacheck
            pkgs.vimPlugins.mini-nvim
          ];

          shellHook = ''
            export NVIM_TEST_MINI_PATH=${pkgs.vimPlugins.mini-nvim}
          '';
        };
      });

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        (_: {
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [
            nixpkgsnur.overlays.default
            (import ./overlays/default.nix {
              inherit copkgs unstable system;
            })
          ];

          # Register flake inputs in the nix registry
          nix.registry.copkgs.flake = copkgs;
          nix.registry.nixpkgs.flake = nixpkgs;
          nix.registry.unstable.flake = unstable;
        })

        ./nixos/configuration.nix
      ];
    };

    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem rec {
      system = "aarch64-darwin";
      modules = [
        (_: {
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [
            nixpkgsnur.overlays.default
            (import ./overlays/default.nix {
              inherit copkgs unstable system;
            })
          ];

          # Register flake inputs in the nix registry
          nix.registry.copkgs.flake = copkgs;
          nix.registry.nixpkgs.flake = nixpkgs;
          nix.registry.unstable.flake = unstable;
        })

        ./osx/configuration.nix
      ];
    };
  };
}
