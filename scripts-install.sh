ls $HOME/.dotfiles/setup/
for script in $HOME/.dotfiles/setup/*; do
  echo "running $script"
  bash "$script"
done
echo "All scripts were executed."
