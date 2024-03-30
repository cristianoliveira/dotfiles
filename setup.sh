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
bkpmv "$HOME"/.zshrc "$DOTFILES_BKP_PATH"/old-zshrc
bkpmv "$HOME"/.ctags "$DOTFILES_BKP_PATH"/old-ctags

mkdir -p $HOME/.config

echo "Add all symbolic links..."
ln -s "$HOME"/.dotfiles/zsh/zshrc "$HOME"/.zshrc
ln -s "$HOME"/.dotfiles/ctags "$HOME"/.ctags

"$HOME"/.dotfiles/resources/alacritty/setup.sh

echo "setup: git"
$HOME/.dotfiles/git/setup.sh

echo "Create local bin folder if it does not exist"
mkdir -p "$HOME"/.local/bin

## if linux 
if [ "$(uname)" == "Linux" ]; then
  echo "Setting up linux"
  bash $HOME/.dotfiles/nix/setup.sh
elif [ "$(uname)" == "Darwin" ]; then
  echo "Setting up OSX"
  bash $HOME/.dotfiles/osx/setup.sh
fi

echo "setup: nvim"
sh $HOME/.dotfiles/nvim/setup.sh

echo "setup: tmux"
$HOME/.dotfiles/tmux/setup.sh

chsh -s /bin/zsh

mkdir -p $HOME/work
mkdir -p $HOME/other
      
echo "Dotfiles has been executed."
echo "Installed: zsh, vim and tmux"
