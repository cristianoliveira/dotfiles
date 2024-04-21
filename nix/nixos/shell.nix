{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = [
      pkgs.xorg.xev
      pkgs.xorg.xmodmap
    ];

    shell = pkgs.zsh;
  }
