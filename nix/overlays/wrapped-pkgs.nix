# Overlay usage: add this file to your overlays list (e.g., `overlays = [ ./overlays/wrapped-pkgs.nix ];`)
# and consume wrapped packages as `pkgs.wrapped.<name>`; `wrapped.delve` is arm64-wrapped on aarch64-darwin.
# Use the current host platform; avoids relying on an undefined `system`.
{ pkgs, ...} : let
  system = pkgs.stdenv.hostPlatform.system;
  delveForArm64 = pkgs.writeShellScriptBin "dlv" ''
    exec arch -arm64 ${pkgs.delve}/bin/dlv "$@"
  '';
  delvePerSystem = if system == "aarch64-darwin" then delveForArm64 else pkgs.delve;
in {
  delve = delvePerSystem;
}
