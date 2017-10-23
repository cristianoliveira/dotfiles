alias :q='exit'
alias :e='vim .'

alias :edot='vim ~/.dotfiles'
alias :zreload='source ~/.zshrc'
alias :run='./run'

alias G=grep

# jump to recently used items
alias a='fasd -a' # any
alias s='fasd -si' # show / search / select
alias d='fasd -d' # directory
alias f='fasd -f' # file
alias z='fasd_cd -d' # cd, same functionality as j in autojump
alias zz='fasd_cd -d -i' # interactive directory jump

alias :slp='pmset sleepnow'

alias habits='\history -1000 -1 | sed "s/^[[:space:]]*[0-9]*[[:space:]]*//" | sort | uniq -c | sort -n -r | head -n 30'

alias wruby='find **/*.rb | entr '

alias running-on='lsof -i'
