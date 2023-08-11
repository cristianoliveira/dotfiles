#!/usr/bin/env sh

set -e  # fail on error
set -u # do not allow unset variables

export DOTFILES_BKP_PATH="$HOME"/.bkpdotfiles/"$(date +%s)"

echo "HOME: $HOME"
echo "DOTFILES_BKP_PATH: $DOTFILES_BKP_PATH"

bkpmv() {
  if [ -x "$1" ]; then
    mv "$1" "$2"
  else
    echo "$1 does not exist or is not executable"
  fi
  if [ -e "$1" ]; then
    mv "$1" "$2"
  else
    echo "$1 does not exist or is not executable"
  fi
}

echo "Istalling tmux-s helper"
rm -f "$HOME/.dotfiles/bin/tmux-s"
ln -s "$HOME/.dotfiles/tmux/bin/tmux-s" "$HOME/.dotfiles/bin/tmux-s"

echo "Creating backup of your current configurations."
echo "They can be found at: $DOTFILES_BKP_PATH"
mkdir -p "$DOTFILES_BKP_PATH"
bkpmv "$HOME"/.tmux.conf "$DOTFILES_BKP_PATH"/old-tmux.conf
bkpmv "$HOME"/.zshrc "$DOTFILES_BKP_PATH"/old-zshrc
bkpmv "$HOME"/.gitconfig "$DOTFILES_BKP_PATH"/old-gitconfig
bkpmv "$HOME"/.gitignore "$DOTFILES_BKP_PATH"/old-gitignore
bkpmv "$HOME"/.ctags "$DOTFILES_BKP_PATH"/old-ctags
bkpmv "$HOME"/.config/karabiner "$DOTFILES_BKP_PATH"/old-karabiner

echo "Add all symbolic links..."
ln -s "$HOME"/.dotfiles/tmux/tmux.conf "$HOME"/.tmux.conf
ln -s "$HOME"/.dotfiles/zsh/zshrc "$HOME"/.zshrc
ln -s "$HOME"/.dotfiles/git/gitconfig "$HOME"/.gitconfig
ln -s "$HOME"/.dotfiles/git/gitignore "$HOME"/.gitignore
ln -s "$HOME"/.dotfiles/ctags "$HOME"/.ctags
ln -s "$HOME"/.dotfiles/resources/karabiner "$HOME"/.config/karabiner


echo "Setup Vim and installing plugins"
sh "$HOME"/.dotfiles/nvim/setup.sh

chsh -s /bin/zsh

echo "Dotfiles has been executed."
echo "Installed: zsh, vim and tmux"
