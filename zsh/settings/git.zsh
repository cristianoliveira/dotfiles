autoload -U add-zsh-hook
setup_main_branch() {
  if [[ -d ".git" ]]; then
    # To configure a custom $LOCAL_MAIN_BRANCH
    if [[ -f ".git/env.zsh" ]]; then
      source ".git/env.zsh"
    fi

    if [[ -z "$LOCAL_MAIN_BRANCH" ]]; then
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
