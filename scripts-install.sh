set -e # fail on errorgf
set -u # do not allow unset variables

ls $HOME/.dotfiles/setup/
for script in $HOME/.dotfiles/setup/*; do
  echo "running $script"
  bash "$script"
done
echo "All scripts were executed."
