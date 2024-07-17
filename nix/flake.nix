{
  description = "Nixos config flake - v1";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # OSX
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    co-pkgs.url = "github:cristianoliveira/nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, co-pkgs, ... }:
    let 
      nixUpdateConfig = import ./nix-update-config.nix { pkgs = import nixpkgs { system = "aarch64-darwin"; }; };
    in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: { 
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [ 
            (final: prev: { mypkgs = import co-pkgs { inherit pkgs; }; })
          ];

          # environment.systemPackages = [
          #   nixUpdateConfig
          # ];
        })
        ./nixos/configuration.nix

        # {
        #   environment.systemPackages = [
        #     (import ./nix-update-config.nix { pkgs = import nixpkgs { system = "aarch64-darwin"; }; })
        #   ];
        # }
      ];
    };
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ pkgs, ... }: { 
          # Injects mypkgs into nixpkgs as pkgs.mypkgs
          nixpkgs.overlays = [ 
            (final: prev: { mypkgs = import co-pkgs { inherit pkgs; }; })
          ];

          # environment.systemPackages = [
          #   nixUpdateConfig
          # ];
        })

        ./osx/configuration.nix

        # {
        #   environment.systemPackages = [
        #     (import ./nix-update-config.nix { pkgs = import nixpkgs { system = "aarch64-darwin"; }; })
        #   ];
        # }
      ];
    };

    packages."x86_64-linux".makeHomeDir = import ./nix-update-config.nix {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    };
    packages."aarch64-darwin".makeHomeDir = import ./nix-update-config.nix {
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
    };

    devShells."x86_64-linux".default = import ./development-environment.nix { inherit nixpkgs; };
    devShells."aarch64-darwin".default = import ./development-environment.nix { inherit nixpkgs; };
  };
}
