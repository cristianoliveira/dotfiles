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

echo "Creating backup of your current configurations."
echo "They can be found at: $DOTFILES_BKP_PATH"
mkdir -p "$DOTFILES_BKP_PATH"
bkpmv "$HOME"/.tmux.conf "$DOTFILES_BKP_PATH"/old-tmux.conf
bkpmv "$HOME"/.zshrc "$DOTFILES_BKP_PATH"/old-zshrc
bkpmv "$HOME"/.gitconfig "$DOTFILES_BKP_PATH"/old-gitconfig
bkpmv "$HOME"/.gitignore "$DOTFILES_BKP_PATH"/old-gitignore
bkpmv "$HOME"/.ctags "$DOTFILES_BKP_PATH"/old-ctags
bkpmv "$HOME"/.config/karabiner "$DOTFILES_BKP_PATH"/old-karabiner
bkpmv "$HOME"/.config/alacritty "$DOTFILES_BKP_PATH"/old-alacritty

mkdir -p $HOME/.config

echo "Add all symbolic links..."
ln -s "$HOME"/.dotfiles/tmux/tmux.conf "$HOME"/.tmux.conf
ln -s "$HOME"/.dotfiles/zsh/zshrc "$HOME"/.zshrc
ln -s "$HOME"/.dotfiles/git/gitconfig "$HOME"/.gitconfig
ln -s "$HOME"/.dotfiles/git/gitignore "$HOME"/.gitignore
ln -s "$HOME"/.dotfiles/ctags "$HOME"/.ctags
ln -s "$HOME"/.dotfiles/resources/karabiner "$HOME"/.config/karabiner
ln -s $HOME/.dotfiles/resources/alacritty "$HOME"/.config/alacritty

echo "Create local bin folder if it does not exist"
mkdir -p "$HOME"/.local/bin

## if linux 
if [ "$(uname)" == "Linux" ]; then
  echo "Setting up linux"
  bash $HOME/.dotfiles/linux/setup.sh
elif [ "$(uname)" == "Darwin" ]; then
  echo "Setting up OSX"
  bash $HOME/.dotfiles/osx/setup.sh
fi

echo "Setup Vim and installing plugins"
sh $HOME/.dotfiles/nvim/setup.sh

chsh -s /bin/zsh

mkdir -p $HOME/work
mkdir -p $HOME/other
      
echo "Dotfiles has been executed."
echo "Installed: zsh, vim and tmux"
