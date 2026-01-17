autoload -U add-zsh-hook
setup_main_branch() {
  if [[ -d "$PWD/.git" ]]; then
    # To configure a custom $LOCAL_MAIN_BRANCH
    if [[ -f ".git/mainbranch" ]]; then
      LOCAL_MAIN_BRANCH="$(cat .git/mainbranch 2>/dev/null)"
    elif [[ -f ".git/main-branch" ]]; then
      LOCAL_MAIN_BRANCH="$(cat .git/main-branch 2>/dev/null)"
    else
      local has_main_branch="$(git branch --list main)"
      if [ -n "$has_main_branch" ]; then
          LOCAL_MAIN_BRANCH='main'
      else
          LOCAL_MAIN_BRANCH='master'
      fi
    fi

    MAIN_BRANCH="$LOCAL_MAIN_BRANCH"
    echo "The 'main' branch for this repo: $MAIN_BRANCH"
  fi
}
add-zsh-hook chpwd setup_main_branch
setup_main_branch

# Remote main branch
export REMOTE_MAIN_BRANCH=origin/$LOCAL_MAIN_BRANCH
