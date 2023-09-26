alias :q='exit'
alias :e='vim .'

alias :zreload='source ~/.zshrc'

alias G=grep

alias habits='\history -1000 -1 | sed "s/^[[:space:]]*[0-9]*[[:space:]]*//" | sort | uniq -c | sort -n -r | head -n 30'

alias running-on='lsof -i'

alias cmdf='\history | grep'
