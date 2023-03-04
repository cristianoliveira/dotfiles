# This is default, but may vary by project.
# See '../settings/git.zsh' how to configure a different $LOCAL_MAIN_BRANCH
MAIN_BRANCH='main'

# git show
alias gsh='git show'
alias gshw='git show'
alias gshow='git show'

# git stash
alias gstsh='git stash'
alias gst='git stash'
alias gstp='git stash pop'
alias gsta='git stash apply'

# git merge
alias gm='git merge'
alias gms='git merge --squash'
alias gmc='git merge --continue'

# git rebase
alias gr='git rebase'
alias gra='git rebase --abort'
alias ggrc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbom='git rebase origin/"$MAIN_BRANCH"'

# git log
alias gl='git l'
alias glg='git l --grep'
alias glog='git l'

# git fetch
alias gf='git fetch'
alias gfp='git fetch --prune'
alias gfa='git fetch --all'
alias gfap='git fetch --all --prune'
alias gfch='git fetch'

# git diff
alias gd='git diff'
alias gdno='git diff --name-only'
# Staged and cached are the same thing
alias gdc='git diff --cached -w'
alias gds='git diff --staged -w'

# git pull
alias gpull='git pull'
alias gpl='git pull'
alias gplr='git pull --rebase'

# git push
alias gp='git push -u'
alias gps='git push'
alias gpush='git push'
alias gpushu='git push -u' # it sets the upstream for the given remote/branch
alias gpn='git push --no-verify' # avoid prehooks
alias gpf='git push --force-with-lease'
alias gp!='git push --no-verify' # avoid prehooks
alias gp!!='git push --no-verify --force-with-lease' # avoid prehooks and force

# git reset
alias grs='git reset'
alias grsh='git reset --hard'
alias grsth='git reset --hard'
alias grsom='git reset --hard origin/"$MAIN_BRANCH"'
alias grshom='git reset --hard origin/"$MAIN_BRANCH"'
alias grsthom='git reset --hard origin/"$MAIN_BRANCH"'
alias grst!='git reset --hard origin/"$MAIN_BRANCH"'

# git clean
alias gcln='git clean'
alias gclnf='git clean -df'
alias gclndfx='git clean -dfx'

# git submodule
alias gsm='git submodule'
alias gsmi='git submodule init'
alias gsmu='git submodule update'

# git checkout
alias gch='git checkout'
alias gchb='git checkout -b'
alias gch='git checkout'
alias gchm='git checkout "$MAIN_BRANCH"'
alias gchd='git checkout develop'

# git branch
alias gbo='git branch --sort=-committerdate'
alias gb='git branch --sort=-committerdate'
alias gbl='git branch --sort=-committerdate| head -n 1'
alias gdmb='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'
alias gnb='git nb' # new branch aka checkout -b
alias gb='git b'
alias gbh='git branch --sort=-committerdate | head -n'
alias gclb='git branch --sort=-committerdate | head -n 1 | pbcopy'
alias gbsync="~/.dotfiles/zsh/scripts/git-branch-sync"
alias gbls="git branch --list --format='%(refname:short)'"

# git helpers
alias gwip='git add . && git commit -m "WIP" --no-verify'
alias goverride='git push origin +$(git branch | grep \* | cut -d ' ' -f2)'
alias gdfb="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gclnb='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'
alias gmlb='git merge `git branch --sort=-committerdate| head -n 1`'
alias gdm='git diff origin/"$MAIN_BRANCH"'
alias gllc='git log --format="%H" -n 1'
alias gpub='grb publish'
alias gtr='grb track'
alias glf='git follow'
alias co='git co'
alias gt='git t'
alias gbg='git bisect good'
alias gbb='git bisect bad'
alias gi='vim .gitignore'
alias gcm='git ci -m'
alias gcim='git ci -m'
alias gci='git ci'
alias gco='git co'
alias gcp='git cp'
alias ga='git add -A'
alias gap='git add -p'
alias guns='git unstage'
alias gunc='git uncommit'
alias gam='git amen --reset-author'
alias grmv='git remote -v'
alias grmr='git remote rm'
alias grad='git remote add'
alias gs='git status'

alias gmt="git mergetool"
alias gamd='git commit --amend'
alias gamd!='git commit --amend --no-edit'

alias gchbm="git checkout origin/\$MAIN_BRANCH && git checkout -b"

# git [ch]eckout [p]ick branch
alias gchp='git checkout $(g bls | fzf)'
