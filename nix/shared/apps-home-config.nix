{ pkgs ? import <nixpkgs> {}, ... }:
  pkgs.stdenv.mkDerivation {
    name = "home-config";
    src = ../.;
    dontBuild = true;
   postInstall = ''
      echo "FOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO"
      echo "FOOOOOOOOOOOOOOOOO" > ~/testnix.txt
    '';
  }
