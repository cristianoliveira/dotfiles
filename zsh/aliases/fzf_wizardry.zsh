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

# fzf git checkout (pick branch)
local git_branch_formatted="git branch --sort=committerdate --format='%(refname:short) [%(committerdate:relative)]'"
local alias_fgb="$git_branch_formatted | fzf | awk '{print \$1}'"
alias fgb=$alias_fgb
alias fgch="git checkout \$($alias_fgb)"
