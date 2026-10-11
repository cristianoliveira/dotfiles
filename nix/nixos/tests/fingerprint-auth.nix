# Run from repository root; no authentication or activation occurs:
# nix eval --impure --expr 'let f = builtins.getFlake (toString ./nix); in
#   import ./nix/nixos/tests/fingerprint-auth.nix {
#     config = f.nixosConfigurations.nixos.config; lib = f.inputs.nixpkgs.lib;
#   }'
{ config, lib }:
let
  services = config.security.pam.services;
  passwordFirst = name:
    let
      auth = services.${name}.rules.auth;
    in
    assert lib.assertMsg
      (auth.unix.enable && auth.unix.control == "sufficient")
      "${name}: a correct password must be sufficient";
    assert lib.assertMsg
      (auth.fprintd.enable && auth.fprintd.control == "sufficient"
        && auth.unix.order < auth.fprintd.order)
      "${name}: fingerprint must be a fallback after password";
    assert lib.assertMsg
      (auth.deny.enable && auth.deny.control == "required"
        && auth.fprintd.order < auth.deny.order)
      "${name}: failed password and fingerprint must reach denial";
    true;
in
assert lib.assertMsg
  (services.sddm.rules.auth.login.control == "substack"
    && services.sddm.rules.auth.login.modulePath == "login")
  "SDDM must use the tested login authentication stack";
assert lib.all passwordFirst [ "login" "swaylock" ];
true
