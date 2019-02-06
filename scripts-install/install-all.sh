for script in ~/.dotfiles/scripts-install/*.sh; do
  bash "$scripts"
done
echo "All scripts were executed."
