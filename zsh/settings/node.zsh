echo "Setting node env..."

function lazy_load_nvm() {
  export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  export NVM_NODEJS_ORG_MIRROR=http://nodejs.org/dist
}

function nvm () {
  lazy_load_nvm
  nvm $@
}
