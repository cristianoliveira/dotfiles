# Nightly packages
# This file exports a function that takes pkgs and returns a set of nightly/custom packages
# Usage: nightly = (import ./nightly-pkgs.nix) prev;
pkgs: {

  codex = let
    # NOTE: Update this version as needed and adjust sha256 accordingly
    # If you are not sure about the sha256, just use empty string ""
    # and nix will tell you the correct one
    version = "0.63.0";
    # Determine the architecture-specific URL
    arch = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "aarch64-apple-darwin"
      else "x86_64-apple-darwin"
    else if pkgs.stdenv.isAarch64 then "aarch64-unknown-linux-gnu"
    else "x86_64-unknown-linux-gnu";

    sha256 = if pkgs.stdenv.isDarwin then
      "sha256-omm9GvTHYOSIFmdmtpq7eC+6h6vD889geLoMDGw4pu4=" else 
      ""; # FIXME for linux

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-${arch}.zst";
      inherit sha256;
    };
  in pkgs.stdenv.mkDerivation {
    pname = "codex";
    inherit version;
    
    nativeBuildInputs = [ pkgs.zstd ];
    
    # Skip default unpack phase since we're handling a single compressed file
    dontUnpack = true;
    
    buildPhase = ''
      runHook preBuild
      zstd -d ${src} -o codex
      chmod +x codex
      runHook postBuild
    '';
    
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp codex $out/bin/codex
      runHook postInstall
    '';
    
    meta = with pkgs.lib; {
      description = "Codex code agent";
      homepage = "https://github.com/openai/codex";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
    };
  };

}
