echo "Setting go environment..."

# Golang
export GOPATH="$HOME/golang/"
export PATH=$PATH:$GOPATH/bin

# Add GVM to the PATH. So go versions are managed by GVM
GVM="$HOME/.gvm/scripts/gvm"
if [[ -f "$GVM" ]]; then
    echo "$GVM exists. Loading..."
    source "$GVM"
else
    echo "No custom $CUSTOM_ZSHRC file found"
fi
