if [ -z "$NIX_ENV" ]; then
   . "$HOME/.asdf/asdf.sh"

   # append completions to fpath
   fpath=(${ASDF_DIR}/completions $fpath)
fi
