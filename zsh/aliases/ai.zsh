alias ai="aichat"
alias aish="aichat -c -r %shell%"
alias aishe="aichat -c -r %shell% -e"

# Generate ai outputs
alias aig-test="aichat -c -r dev-tdd -f $(git ls-files --modified --exclude-standard --others) "
alias aig-snippet="aichat -c -r dev-snippet"
alias aig-with-git="aichat -f $(git ls-files --modified --exclude-standard --others) "

# Ai expert assistants
alias aiss-linux="aichat -c -r exp-linux"

alias oc="opencode"
alias oc-with-mcp="opencode --config opencode-with-mcps.json"

# PI agent
alias pie="pi explore --in"
alias pide="pi --model deepseek-v4-pro"
alias pipt="pi --model gpt-5.5"
alias pi-models="pi --list-models"
