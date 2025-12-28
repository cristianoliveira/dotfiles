{ copkgs, unstable,  system, ... }: final: prev: {
  # COpkgs - are my packages (Cristian Oliveira packages)
  # https://github.com/cristianoliveira/nixpkgs
  copkgs = copkgs.packages.x86_64-linux;

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
