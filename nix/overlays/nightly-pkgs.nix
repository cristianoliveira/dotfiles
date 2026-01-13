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
      "sha256-fRBfWCLyDa1EueD2AanZ7+YVUK+2SBcsAeX9OdPnMkM="; # FIXME for linux

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

  opencode = let
    version = "1.1.18";

    # Determine the architecture-specific file and URL
    archFile = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "opencode-darwin-arm64.zip"
      else "opencode-darwin-x64.zip"
    else if pkgs.stdenv.isAarch64 then "opencode-linux-arm64.tar.gz"
    else "opencode-linux-x64.tar.gz";

    # Update sha256 as needed - use empty string "" and nix will tell you the correct one
    sha256 = if pkgs.stdenv.isDarwin then
      "sha256-g+msHIjtF7ZY2qC/f0ry2QDN3tZeuedmJ81Y5j69xWw="
      else
      "sha256-0lsa30ylxldq5195pq950j2k31m9jh8g99f04c8zyin7bkyl6adw"

    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${archFile}";
      inherit sha256;
    };
  in pkgs.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    nativeBuildInputs = if pkgs.stdenv.isDarwin then [ pkgs.unzip ] else [ pkgs.gnutar pkgs.gzip ];

    sourceRoot = ".";

    unpackPhase = if pkgs.stdenv.isDarwin then ''
      runHook preUnpack
      unzip ${src}
      runHook postUnpack
    '' else ''
      runHook preUnpack
      tar xzf ${src}
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp opencode $out/bin/opencode
      chmod +x $out/bin/opencode
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "OpenCode - AI-powered code editor";
      homepage = "https://github.com/anomalyco/opencode";
      platforms = platforms.unix;
      maintainers = [ ];
    };
  };

}
