### GIT
# [f]zf (fuzzy find) [g]it [ch]eckout [p]ick branch
alias fgch='git checkout $(g bls | fzf)'
# git [ch]eckout [p]ick from [t]op N
alias fgcht10='git checkout $(g bls --sort=-committerdate | head -n 10 | fzf)'
alias fgcht20='git checkout $(g bls --sort=-committerdate | head -n 20 | fzf)'

# fzf git log (return commit hash)
local git_log_formatted="git log --no-merges --pretty=format:\"%h %s [%cn - %cr]\""
local fzf_git_log_formatted="$git_log_formatted | fzf"
alias fgl="$fzf_git_log_formatted | awk '{print \$1}'"
alias fglt10="$fzf_git_log_formatted | head -n 10 | fzf | awk '{print \$1}'"
alias fglt20="$fzf_git_log_formatted | head -n 20 | fzf | awk '{print \$1}'"
