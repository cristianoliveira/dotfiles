{ pkgs }:
  pkgs.mkShell {
    buildInputs = with pkgs; [
      statix # nix linter

      nil # nix lsp for vim
    ];
  }
