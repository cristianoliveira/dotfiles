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
    ngrok

    nil # nix LSP
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
    # (if mypkgs then mypkgs.funzzy else null)
    # (if mypkgs then mypkgs.ergo else null)

    # Essential pkgs
    curl
    wget
    bc
    htop
    gnumake

    # Languages
    nodejs_20 # npm set prefix ~/.npm-global
    python3
    python311Packages.pip
    go
    cargo #
  ];
}
