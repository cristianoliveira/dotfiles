echo "Setting ruby environment..."

# RVM load
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm

# Rbenv
eval "$(rbenv init -)"
