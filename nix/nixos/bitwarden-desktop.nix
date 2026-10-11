{ pkgs }:
pkgs.symlinkJoin {
  name = "bitwarden-desktop";
  paths = [ pkgs.bitwarden-desktop ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  # Avoid keyring prompts for Bitwarden's access token only. This stores the
  # token unencrypted on disk; vault encryption and other apps are unchanged.
  postBuild = ''
    wrapProgram "$out/bin/bitwarden" --set ACCESS_TOKEN_LOCATION DISK
  '';
}
