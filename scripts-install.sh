ls $HOME/.dotfiles/scripts-install/
for script in $HOME/.dotfiles/scripts-install/*; do
  echo "running $script"
  bash "$script"
done
echo "All scripts were executed."
