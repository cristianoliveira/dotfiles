alias docker-clean-containers='docker rm -f $(docker ps -a -q)'
alias docker-clean-images='docker rmi -f $(docker images -a -q'
alias docker-clean-volumes='docker volume rm $(docker volume ls -q)'

# docker-compose
alias dcc=docker-compose
alias dccu=docker-compose up
alias dccs=docker-compose stop
