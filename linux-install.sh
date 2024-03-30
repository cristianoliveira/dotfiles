set -e  # fail on error
set -u # do not allow unset variables


# if nix isn't installed, install it
if ! command -v nix-env &> /dev/null; then
  echo "Nix is not installed. Make sure to install it."
fi

sudo nixos-rebuild switch --flake $HOME/.dotfiles/nix#nixos

echo "Setup linux machine"
bash $HOME/.dotfiles/setup.sh
