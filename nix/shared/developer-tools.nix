{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Development environment
    git
    tmux
    zsh
    oh-my-zsh
    zsh-completions
    zsh-syntax-highlighting
    diff-so-fancy
    fzf
    ripgrep
    jq

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
    python311Packages.pynvim
    python311Packages.pip
    # For UltiSnips
    python312Packages.pynvim

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
    python3
    uv # Python package installer
    python311Packages.pip
    go
    cargo #

    # AI and related 
    claude-code
    nur.repos.charmbracelet.crush
    unstable.aichat
    nightly.codex
  ];
}
