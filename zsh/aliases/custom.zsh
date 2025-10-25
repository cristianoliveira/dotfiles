alias :q='exit'
alias :e='vim .'

alias :zreload='source ~/.zshrc'

alias G=grep

alias habits='\history -1000 -1 | sed "s/^[[:space:]]*[0-9]*[[:space:]]*//" | sort | uniq -c | sort -n -r | head -n 30'

alias running-on='lsof -i'

alias cmdf='\history | grep'

# Helper aliases
alias dups='grep -v "^\s*$" | sort | uniq -d'

# Ripgrep aliases
alias rgh='rg --hidden'

# Use zoxide  
alias cdd='z'

# Osx Brew arch -arm64 alias
alias abrew='arch -arm64 brew'

# If linux alias open
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  alias open="xdg-open"
fi
