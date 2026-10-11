# Run from repository root:
# nix build --impure --no-link --expr 'let f = builtins.getFlake (toString ./nix);
#   in import ./nix/nixos/tests/bitwarden-launcher.nix {
#     pkgs = f.nixosConfigurations.nixos.pkgs;
#   }'
{ pkgs }:
let
  fakeBitwarden = pkgs.writeShellScriptBin "bitwarden" ''
    set -eu
    test "$ACCESS_TOKEN_LOCATION" = DISK
    test "$#" -eq 2
    test "$1" = 'bitwarden://test'
    test "$2" = 'argument with spaces'
  '';
  bitwarden = import ../bitwarden-desktop.nix {
    pkgs = pkgs // { bitwarden-desktop = fakeBitwarden; };
  };
in
pkgs.runCommand "bitwarden-launcher-test" { } ''
  # The launcher must set the value even when it is unset or inherited.
  env -u ACCESS_TOKEN_LOCATION ${bitwarden}/bin/bitwarden \
    'bitwarden://test' 'argument with spaces'

  export ACCESS_TOKEN_LOCATION=DEFAULT
  ${bitwarden}/bin/bitwarden 'bitwarden://test' 'argument with spaces'

  # Other applications keep the parent environment.
  test "$ACCESS_TOKEN_LOCATION" = DEFAULT
  touch "$out"
''
