# So there is this feature of Ultisnips that allows you to jump to the 
# snippet file related to the current file you are editing. I use that A LOT!
# It made me ditch the preconfigured snippets from a plugin and create my own
# snippets incrementally. Now it's tailored to my needs.
#
# I want to emulate that feature in my dotfiles. I want to be able to jump to
# defines env variables with path to places in the dotfile
#
# So I can edit them easily
# Eg. `vim $_DF_NIX`
export _DF_ROOT=$HOME/.dotfiles
export _DF_NIX=$HOME/.dotfiles/nix
export _DF_VIM=$HOME/.dotfiles/nvim
export _DF_ZSH=$HOME/.dotfiles/zsh
export _DF_GIT=$HOME/.dotfiles/git
export _DF_TMX=$HOME/.dotfiles/tmux
export _DF_BIN=$HOME/.dotfiles/bin

alias cd-nvim-plugins='cd $_DF_VIM/lua'
alias cd-aliases='cd $_DF_ROOT/aliases'
alias cd-functions='cd $_DF_ROOT/functions'
alias cd-nix='cd $_DF_NIX'
alias cd-vim='cd $_DF_VIM'
alias cd-zsh='cd $_DF_ZSH'
alias cd-git='cd $_DF_GIT'
alias cd-tmx='cd $_DF_TMX'
alias cd-bin='cd $_DF_BIN'
alias cd-df='cd $_DF_ROOT'
