alias docker-daemon='colima'
alias dk=docker

alias dk-clean-containers='docker rm -f $(docker ps -a -q)'
alias dk-clean-images='docker rmi -f $(docker images -a -q'
alias dk-clean-volumes='docker volume rm $(docker volume ls -q)'

# docker-compose
alias dcc='docker-compose'
alias dccu='docker-compose up'
alias dccd='docker-compose up'
alias dccs='docker-compose stop'
alias dcce='docker-compose exec'
alias dccit='docker-compose exec -it'

# Docker related but not docker
alias dkrs='colima start --network-address' # docker runtime start
