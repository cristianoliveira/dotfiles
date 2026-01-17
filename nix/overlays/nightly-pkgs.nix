# Nightly packages
# This file exports a function that takes pkgs and returns a set of nightly/custom packages
# Usage: nightly = (import ./nightly-pkgs.nix) prev;
#
# To update sha256 hashes:
# 1. Fetch hash: nix-prefetch-url https://github.com/openai/codex/releases/download/rust-v${version}/codex-${arch}.zst
# 2. Convert to SRI: nix hash convert --hash-algo sha256 <hash-from-step-1>
# Example for Darwin aarch64:
#   nix-prefetch-url https://github.com/openai/codex/releases/download/rust-v0.80.0/codex-aarch64-apple-darwin.zst
#   nix hash convert --hash-algo sha256 06wg50zymn83a8irbw67nir9ahn2vqszqjibcw8gzpw3r6ds5xpj
pkgs: {

  codex = let
    # NOTE: Update this version as needed and adjust sha256 accordingly
    # If you are not sure about the sha256, just use empty string ""
    # and nix will tell you the correct one
    version = "0.80.0"; # v0.80.0
    # Determine the architecture-specific URL
    arch = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "aarch64-apple-darwin"
      else "x86_64-apple-darwin"
    else if pkgs.stdenv.isAarch64 then "aarch64-unknown-linux-gnu"
    else "x86_64-unknown-linux-gnu";

    sha256 = if pkgs.stdenv.isDarwin then
      "sha256-8vaim8mD3/8QZytK/DXewkKVcrTH8JUjUgPZ6j8ojxs=" else
      "sha256-34+vBxhfxHZokKSNfjhltZcsqU1jk894gpd26WsbG3E=";

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
      # nix-prefetch-url --unpack https://github.com/anomalyco/opencode/releases/download/v1.1.18/opencode-linux-x64.tar.gz
      "sha256-g+msHIjtF7ZY2qC/f0ry2QDN3tZeuedmJ81Y5j69xWw=" else
      # nix-prefetch-url --unpack https://github.com/anomalyco/opencode/releases/download/v1.1.18/opencode-linux-arm64.tar.gz
      "sha256-0lsa30ylxldq5195pq950j2k31m9jh8g99f04c8zyin7bkyl6adw";

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


  # gob - Process manager for AI agents (and humans)
  gob = let
    version = "2.2.2";

    # Determine the architecture-specific file
    archFile = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "gob_${version}_darwin_arm64.tar.gz"
      else "gob_${version}_darwin_amd64.tar.gz"
    else if pkgs.stdenv.isAarch64 then "gob_${version}_linux_arm64.tar.gz"
    else "gob_${version}_linux_amd64.tar.gz";

    # Update sha256 as needed - use empty string "" and nix will tell you the correct one
    # nix-prefetch-url https://github.com/juanibiapina/gob/releases/download/v2.2.2/gob_2.2.2_darwin_arm64.tar.gz
    # nix-prefetch-url https://github.com/juanibiapina/gob/releases/download/v2.2.2/gob_2.2.2_darwin_amd64.tar.gz
    # nix-prefetch-url https://github.com/juanibiapina/gob/releases/download/v2.2.2/gob_2.2.2_linux_arm64.tar.gz
    # nix-prefetch-url https://github.com/juanibiapina/gob/releases/download/v2.2.2/gob_2.2.2_linux_amd64.tar.gz
    sha256 = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "sha256-/2OieYYH9y4s7DOrPWKhQa4jUHLwCSP5f1alxB7ucfA="
      else "sha256-7Yfs6qkAXRA6cjHdt8Xe8JgUKEzEXBwgruD/2dj4q1w="
    else if pkgs.stdenv.isAarch64 then "sha256-YZCn54r0bOn0yZqKuPmfu6IuYz4yg1w1ll8M2e1JeyM="
    else "sha256-mdLqKwvsh2YHMMpkpxHmpXbRnIUOOxoeW1LwCxHhXyE=";

    src = pkgs.fetchurl {
      url = "https://github.com/juanibiapina/gob/releases/download/v${version}/${archFile}";
      inherit sha256;
    };
  in pkgs.stdenv.mkDerivation {
    pname = "gob";
    inherit version;

    nativeBuildInputs = [ pkgs.gnutar pkgs.gzip ];

    sourceRoot = ".";

    unpackPhase = ''
      runHook preUnpack
      tar xzf ${src}
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp gob $out/bin/gob
      chmod +x $out/bin/gob
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Process manager for AI agents (and humans)";
      homepage = "https://github.com/juanibiapina/gob";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = [ ];
    };
  };

}
