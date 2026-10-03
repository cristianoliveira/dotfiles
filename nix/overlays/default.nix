{ copkgs, unstable, system, aerospace-gestures ? null, ... }: final: prev:
(copkgs.overlays.default final prev) // {
  # COpkgs - are my packages (Cristian Oliveira packages)
  # https://github.com/cristianoliveira/nixpkgs
  copkgs = copkgs.packages.${system};

  # aerospace-gestures built from source because released versions do not
  # support pinch bindings yet. Null on non-darwin hosts: aerospace-gestures
  # is darwin-only software and no host besides the darwin one uses it.
  aerospace-gestures =
    aerospace-gestures.packages.${system}.aerospace-gestures or null;

  # Unstable packages namespace - access via pkgs.unstable.<pckg>
  # NOTE: this is comes directly from nixpkgs
  unstable = import unstable {
    inherit system;
    config = { allowUnfree = true; };
  };

  # Nightly packages namespace - access via pkgs.nightly.codex
  # NOTE: this is comes directly from releases
  nightly = (import ./nightly-pkgs.nix) prev;

  # Wrapped packages namespace
  # Standard packages that are wrapped for extra functionality
  wrapped = (import ./wrapped-pkgs.nix) prev;
}
