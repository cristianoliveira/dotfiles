if [ -z "$ASDF_INIT" ]; then
   . "$HOME/.asdf/asdf.sh"

   # append completions to fpath
   fpath=(${ASDF_DIR}/completions $fpath)
else
   echo "asdf already loaded."
fi
