{ pkgs ? import <nixpkgs> {}, ... }: let
  # Wrap dlv with `arch -arm64 ...` to make it work on arm64
  delveForArm64 = pkgs.writeShellScriptBin "dlv" ''
    exec arch -arm64 ${pkgs.delve}/bin/dlv "$@"
  '';
  delvePerSystem = if system == "aarch64-darwin" then delveForArm64 else pkgs.delve;
in {
  environment.systemPackages = with pkgs; [
    go

    # Debugging
    delvePerSystem
  ];
}
