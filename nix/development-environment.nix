{ pkgs }:
  pkgs.mkShell {
    buildInputs = with pkgs; [
      statix # nix linter
    ];
  }
