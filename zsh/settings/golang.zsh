# Golang
export GOPATH="$HOME/golang"
export PATH=$GOPATH/bin:$PATH

# Add GVM to the PATH. So go versions are managed by GVM
lazy_load_gvm() {
  GVM="$HOME/.gvm/scripts/gvm"
  if [[ -f "$GVM" ]]; then
      source "$GVM"
  else
      echo "No custom $CUSTOM_ZSHRC file found"
  fi
}

gvm() {
  lazy_load_gvm

  gvm $@
}
