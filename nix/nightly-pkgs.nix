# Nightly packages
# This file exports a function that takes pkgs and returns a set of nightly/custom packages
# Usage: nightly = (import ./nightly-pkgs.nix) prev;
pkgs: {

  codex = let
    version = "0.55.0"; # Update this version as needed
    sha256 = "sha256-nY2AYS3zFittsXlvO9UulyedKk1p7bnED3Q2aSxch+M="; # Placeholder for the SHA256 hash of the binary
    # Determine the architecture-specific URL
    arch = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "aarch64-apple-darwin"
      else "x86_64-apple-darwin"
    else if pkgs.stdenv.isAarch64 then "aarch64-unknown-linux-gnu"
    else "x86_64-unknown-linux-gnu";
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
