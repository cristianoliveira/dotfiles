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
    # NOTE: not using it 
    # ngrok

    # NOTE: this is used by nvim settup
    # See also: ../../nvim/lua/customization/settings/lsp.lua
    nixd # nix lsp (full fledged)
    nil # nix LSP (just linter)
    gnused # bye macOs annoying sed

    # Nvim stuff
    vim
    neovim 
    python311Packages.pynvim
    python311Packages.pip

    # Nvim plugins dependencies
    libiconv # VIM: Required to build lsp in Mason
    gcc # VIM: Required to build lsp in Mason

    # My custom pkgs
    copckgs.funzzy
    # (if mypkgs then mypkgs.ergo else null)

    # Essential pkgs
    curl
    wget
    bc
    htop
    gnumake

    universal-ctags

    # Languages
    nodejs_22 # npm set prefix ~/.npm-global
    python3
    python311Packages.pip
    go
    cargo #

    (pkgs.writeScriptBin "snipgpt" ''#!${pkgs.stdenv.shell}
      NODE_NO_WARNINGS=1 npx snipgpt "$@"
    '')
  ];
}
