#!/usr/bin/env sh

set -e  # fail on error
set -u # do not allow unset variables

export DOTFILES_BKP_PATH="$HOME"/.bkpdotfiles/"$(date +%s)"
export HOME_PATH=${HOME_PATH:-$HOME}

echo "HOME_PATH: $HOME_PATH"
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

echo "Creating backup of your current configurations."
echo "They can be found at: $DOTFILES_BKP_PATH"
mkdir -p "$DOTFILES_BKP_PATH"
bkpmv "$HOME_PATH"/.tmux.conf "$DOTFILES_BKP_PATH"/old-tmux.conf
bkpmv "$HOME_PATH"/.zshrc "$DOTFILES_BKP_PATH"/old-zshrc
bkpmv "$HOME_PATH"/.gitconfig "$DOTFILES_BKP_PATH"/old-gitconfig
bkpmv "$HOME_PATH"/.gitignore "$DOTFILES_BKP_PATH"/old-gitignore
bkpmv "$HOME_PATH"/.ctags "$DOTFILES_BKP_PATH"/old-ctags
bkpmv "$HOME_PATH"/.config/karabiner "$DOTFILES_BKP_PATH"/old-karabiner

echo "Add all symbolic links..."
ln -s "$HOME_PATH"/.dotfiles/tmux/tmux.conf "$HOME_PATH"/.tmux.conf
ln -s "$HOME_PATH"/.dotfiles/zsh/zshrc "$HOME_PATH"/.zshrc
ln -s "$HOME_PATH"/.dotfiles/git/gitconfig "$HOME_PATH"/.gitconfig
ln -s "$HOME_PATH"/.dotfiles/git/gitignore "$HOME_PATH"/.gitignore
ln -s "$HOME_PATH"/.dotfiles/ctags "$HOME_PATH"/.ctags
ln -s "$HOME_PATH"/.dotfiles/resources/karabiner "$HOME_PATH"/.config/karabiner

echo "Istalling tmux-s helper"
rm "$HOME_PATH/.dotfiles/bin/tmux-s"
ln -s "$HOME_PATH/.dotfiles/tmux/bin/tmux-s" "$HOME_PATH/.dotfiles/bin/tmux-s"

echo "Installing zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" &

echo "Setup Vim and installing plugins"
sh "$HOME_PATH"/.dotfiles/vim/setup.sh

chsh -s /bin/zsh

echo "Dotfiles has been executed."
echo "Installed: zsh, vim and tmux"
