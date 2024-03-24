if [ -z "$NIX_ENV" ]; then
   export GOPATH="$HOME/golang"
   export PATH=$GOPATH/bin:$PATH

   . ~/.asdf/plugins/golang/set-env.zsh
fi
