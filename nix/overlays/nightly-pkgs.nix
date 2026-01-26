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
    version = "1.1.36";

    # Determine the architecture-specific file and URL
    # Linux logic matches install script: checks for musl and uses baseline for x64
    archFile = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "opencode-darwin-arm64.zip"
      else "opencode-darwin-x64.zip"
    else if pkgs.stdenv.isLinux then
      let
        arch = if pkgs.stdenv.isAarch64 then "arm64" else "x64";
        # Use baseline for x64 (no AVX2 requirement) for maximum compatibility
        baseline = if pkgs.stdenv.isAarch64 then "" else "-baseline";
        # Check for musl libc (Alpine Linux, NixOS with musl, etc.)
        musl = if pkgs.stdenv.hostPlatform.isMusl then "-musl" else "";
      in "opencode-linux-${arch}${baseline}${musl}.tar.gz"
    else throw "Unsupported platform";

    # Update sha256 as needed - use empty string "" and nix will tell you the correct one
    # Linux x64-baseline: nix-prefetch-url https://github.com/anomalyco/opencode/releases/download/v1.1.36/opencode-linux-x64-baseline.tar.gz
    # Linux x64-baseline-musl: nix-prefetch-url https://github.com/anomalyco/opencode/releases/download/v1.1.36/opencode-linux-x64-baseline-musl.tar.gz
    # Linux arm64: nix-prefetch-url https://github.com/anomalyco/opencode/releases/download/v1.1.36/opencode-linux-arm64.tar.gz
    # Linux arm64-musl: nix-prefetch-url https://github.com/anomalyco/opencode/releases/download/v1.1.36/opencode-linux-arm64-musl.tar.gz
    sha256 = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then
        "sha256-PH9SlAKAcl/IBHlXzCIQAHT4GJgf3ip7mzO5pUFVM04="
      else
        "sha256-848FTxingnXyTs8Ioi3Tt4mSo/VZxkS8ip/NfGRz4V8="
    else if pkgs.stdenv.isLinux then
      if pkgs.stdenv.isAarch64 then
        if pkgs.stdenv.hostPlatform.isMusl then
          "sha256-dqxZd/bDRlPJOTZ9oTVIQowW7cJhl4BGbufRoXS6CWQ="  # arm64-musl
        else
          "sha256-WK68sZvP1geCvbm/okrI9BOfmR02ZLXBOAfc8p3OQII="  # arm64
      else  # x64
        if pkgs.stdenv.hostPlatform.isMusl then
          "sha256-Pl+cO/EsvOqxQEqp+sq4l1Y4PZcUjOmQXe3lZ+aL41U="  # x64-baseline-musl
        else
          "sha256-8xvEkn4vI5J5OYbeeGPXHGcWABlbhtAVdHd09up+ffY="  # x64-baseline
    else throw "Unsupported platform";

    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${archFile}";
      inherit sha256;
    };
  in pkgs.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    nativeBuildInputs = if pkgs.stdenv.isDarwin then [ pkgs.unzip ] else [ pkgs.gnutar pkgs.gzip ];

    # Don't strip the binary - it's built with Bun and stripping breaks it
    dontStrip = true;

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

  # Ferrite - Markdown viewer with mermaid support
  ferrite = let
    version = "0.2.3";

    filename = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "ferrite-macos-arm64.tar.gz"
      else "ferrite-macos-x64.tar.gz"
    else if pkgs.stdenv.isLinux then
      if pkgs.stdenv.isAarch64 then throw "Ferrite v${version} not available for aarch64-linux"
      else "ferrite-linux-x64.tar.gz"
    else throw "Ferrite v${version} unsupported platform";

    sha256 = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "sha256-qKQRoPBq2lktZRQbh80xWR5CLljuv8h6aomVEPowBmg=" else
      "sha256-WxmHjMTr9ihtZVrzB/s31SZepAHGfEyoI5ItWGjH7oI="
    else if pkgs.stdenv.isLinux then
      if pkgs.stdenv.isAarch64 then throw "Ferrite v${version} not available for aarch64-linux"
      else "sha256-81HmxZalj3AsHdxq1AXmpwZchMklWLHnu1gwvIgL0RA="
    else throw "Ferrite v${version} unsupported platform";

    src = pkgs.fetchurl {
      url = "https://github.com/OlaProeis/Ferrite/releases/download/v${version}/${filename}";
      inherit sha256;
    };
  in pkgs.stdenv.mkDerivation {
    pname = "ferrite";
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
      cp ferrite $out/bin/ferrite
      chmod +x $out/bin/ferrite
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Ferrite text editor";
      homepage = "https://github.com/OlaProeis/Ferrite";
      license = licenses.mit;
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

  beads = let
    version = "0.49.0";

    # Determine the architecture-specific file
    archFile = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "beads_${version}_darwin_arm64.tar.gz"
      else "beads_${version}_darwin_amd64.tar.gz"
    else if pkgs.stdenv.isAarch64 then "beads_${version}_linux_arm64.tar.gz"
    else "beads_${version}_linux_amd64.tar.gz";

    # Update sha256 as needed - use empty string "" and nix will tell you the correct one
    # nix-prefetch-url https://github.com/steveyegge/beads/releases/download/v${version}/beads_${version}_darwin_arm64.tar.gz
    # nix-prefetch-url https://github.com/steveyegge/beads/releases/download/v${version}/beads_${version}_darwin_amd64.tar.gz
    # nix-prefetch-url https://github.com/steveyegge/beads/releases/download/v${version}/beads_${version}_linux_arm64.tar.gz
    # nix-prefetch-url https://github.com/steveyegge/beads/releases/download/v${version}/beads_${version}_linux_amd64.tar.gz
    sha256 = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "sha256-6xJ7heheeaKWD+EqkGZVi/znQ579xsZpbe2Lzjozw+A="
      else "sha256-Z+Ovm8QsnYcbnp7zocmzYnoC2wuZRxT4RDnlqlENcxE="
    else if pkgs.stdenv.isAarch64 then "sha256-M5o2uqwta0+GBeamXNpKUZD9IMBtq8ncFrXSlOh7d+4="
    else "sha256-BOJdEYsoehdzizR+HIS0pWmOtcz9hKgC7RzUiyIMwe0=";

    src = pkgs.fetchurl {
      url = "https://github.com/steveyegge/beads/releases/download/v${version}/${archFile}";
      inherit sha256;
    };
  in pkgs.stdenv.mkDerivation {
    pname = "beads";
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
      cp bd $out/bin/bd
      chmod +x $out/bin/bd
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Beads issue tracker and task management";
      homepage = "https://github.com/steveyegge/beads";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = [ ];
    };
  };

  beads_viewer = let
    version = "0.13.0";

    # Determine the architecture-specific file
    archFile = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "bv_${version}_darwin_arm64.tar.gz"
      else "bv_${version}_darwin_amd64.tar.gz"
    else if pkgs.stdenv.isAarch64 then "bv_${version}_linux_arm64.tar.gz"
    else "bv_${version}_linux_amd64.tar.gz";

    # Update sha256 as needed - use empty string "" and nix will tell you the correct one
    # nix-prefetch-url https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_darwin_arm64.tar.gz
    # nix-prefetch-url https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_darwin_amd64.tar.gz
    # nix-prefetch-url https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_linux_arm64.tar.gz
    # nix-prefetch-url https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/bv_${version}_linux_amd64.tar.gz
    sha256 = if pkgs.stdenv.isDarwin then
      if pkgs.stdenv.isAarch64 then "sha256-eCA/NKQ7QT9KEEOtBiwOb9ksxj2k202ENK1tWKOdCEY="
      else "sha256-n7+K0grNaNKDvrJurt25Ow3/2wuWVvrjp38fFWcPYfA="
    else if pkgs.stdenv.isAarch64 then "sha256-dxkewC884pA0exBZFixC2A+VgTw5ZyirnD8Zj9ncAwg="
    else "sha256-8Ux9Brf2u78ljmTB49EBXCAn41WssOl8c+dZ1DZDjkw=";

    src = pkgs.fetchurl {
      url = "https://github.com/Dicklesworthstone/beads_viewer/releases/download/v${version}/${archFile}";
      inherit sha256;
    };
  in pkgs.stdenv.mkDerivation {
    pname = "beads-viewer";
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
      cp bv $out/bin/bv
      chmod +x $out/bin/bv
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Beads viewer for visualizing beads data";
      homepage = "https://github.com/Dicklesworthstone/beads_viewer";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = [ ];
    };
  };

  confluence-cli = let
    version = "1.13.0";
    src = pkgs.fetchFromGitHub {
      owner = "pchuri";
      repo = "confluence-cli";
      rev = "v${version}";
      # Update sha256 as needed - use empty string "" and nix will tell you the correct one
      # nix-prefetch-url https://github.com/pchuri/confluence-cli/archive/refs/tags/v${version}.tar.gz
      sha256 = "sha256-uBViaGC5pqYl6eRf6oO98OQV/rdxevZ9PKN6KQpmMPE=";
    };
  in pkgs.buildNpmPackage {
    pname = "confluence-cli";
    inherit version src;
    npmDepsHash = "sha256-gt/xHaP0PMcgTVlW2GYNnT9UyI9Ay2SksDTw2yHsBsU=";
    dontNpmBuild = true;
    npmPackFlags = [ "--ignore-scripts" ];
    meta = with pkgs.lib; {
      description = "CLI for Confluence";
      homepage = "https://github.com/pchuri/confluence-cli";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = [ cristianoliveira ];
    };
  };

  qmd = let
    version = "1.0.0";
    src = pkgs.fetchFromGitHub {
      owner = "tobi";
      repo = "qmd";
      rev = "88f78314bb22bd23e68bf4d16a447323c2a29b0f";
      # Update sha256 as needed - use empty string "" and nix will tell you the correct one
      # nix-prefetch-url https://github.com/tobi/qmd/archive/refs/tags/v${version}.tar.gz
      sha256 = "sha256-ejJxsUW1KlUobNvweU0cCx224dvAb1jQUfGLrYeSNM8=";
    };
  in pkgs.stdenv.mkDerivation {
    pname = "qmd";
    inherit version src;

    dontStrip = true;

    nativeBuildInputs = [ pkgs.bun pkgs.makeWrapper ];
    buildInputs = [ pkgs.sqlite ];

    buildPhase = ''
      export HOME=$(mktemp -d)
      bun install --frozen-lockfile
    '';

    installPhase = ''
      mkdir -p $out/lib/qmd
      mkdir -p $out/bin

      cp -r node_modules $out/lib/qmd/
      cp -r src $out/lib/qmd/
      cp package.json $out/lib/qmd/

      makeWrapper ${pkgs.bun}/bin/bun $out/bin/qmd \
        --add-flags "$out/lib/qmd/src/qmd.ts" \
        --set DYLD_LIBRARY_PATH "${pkgs.sqlite.out}/lib" \
        --set LD_LIBRARY_PATH "${pkgs.sqlite.out}/lib"
    '';

    meta = with pkgs.lib; {
      description = "On-device search engine for markdown notes, meeting transcripts, and knowledge bases";
      homepage = "https://github.com/tobi/qmd";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = [ ];
    };
  };

}
