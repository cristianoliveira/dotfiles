set -e  # fail on error
set -u # do not allow unset variables

echo "Create local bin folder if it does not exist"
mkdir -p "$HOME"/.local/bin

## if linux 
if [ "$(uname)" == "Linux" ]; then
  echo "Setting up linux"
  bash $HOME/.dotfiles/nix/nixos/setup.sh
elif [ "$(uname)" == "Darwin" ]; then
  echo "Setting up OSX"
  bash $HOME/.dotfiles/nix/osx/setup.sh
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
