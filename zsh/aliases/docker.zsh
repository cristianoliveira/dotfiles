alias docker-clean-containers='docker rm -f $(docker ps -a -q)'
alias docker-clean-images='docker rmi -f $(docker images -a -q'
alias docker-clean-volumes='docker volume rm $(docker volume ls -q)'
