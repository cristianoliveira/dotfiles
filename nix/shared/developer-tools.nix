{ pkgs, ... }:
let
  pythonWithPynvim = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pynvim ]);
in {
  # The default Nix Neovim wrapper disables the Python provider.
  nixpkgs.overlays = [
    (_: prev: {
      neovim = prev.neovim.override { withPython3 = true; };
    })
  ];

  environment.systemPackages = with pkgs; [
    # Development environment
    git
    git-lfs
    codeql
    tmux
    zsh
    oh-my-zsh
    zsh-completions
    zsh-syntax-highlighting
    diff-so-fancy
    fzf
    jq

    tree # Better ls
    ripgrep # Better grep
    fd # Better find

    zoxide # Better cd inspired by z
    gh # GitHub CLI

    # NOTE: not using it
    # ngrok

    # NOTE: this is used by nvim settup
    # See also: ../../nvim/lua/customization/settings/lsp.lua
    nixd # nix lsp (full fledged)
    nil # nix LSP (just linter)
    gnused # bye macOs annoying sed
    coreutils # bye macOs annoying coreutils

    # To manage my dotfiles
    stow

    # Nvim stuff
    vim
    neovim
    python311Packages.pip
    # Neovim's Python provider and UltiSnips require pynvim in the active Python.
    pythonWithPynvim

    # Nvim plugins dependencies
    libiconv # VIM: Required to build lsp in Mason
    gcc # VIM: Required to build lsp in Mason

    # My custom pkgs
    # copkgs.funzzy

    # (if mypkgs then mypkgs.ergo else null)

    # Essential pkgs
    curl
    wget
    bc
    gnumake

    universal-ctags

    # Languages
    nodejs_22 # npm set prefix ~/.npm-global
    python311Packages.pyyaml
    uv # Python package installer
    python311Packages.pip
    cargo #

    # Text-to-speech (training dependencies are not needed for local inference)
    (piper-tts.override { withTrain = false; })

    # Markdown
    nightly.ferrite # Markdown viewer with

    # Devx
    just
    process-compose
  ];

  imports = [
    ./dev-tools/go.nix
    ./dev-tools/ai.nix
  ];
}
