vim.g.ale_lint_delay = 100
vim.g.ale_lint_on_text_changed = 'never'

vim.g.ale_fix_on_save = 1
vim.g.ale_fixers = {
  javascript = {'eslint', 'prettier'},
  typescript = {'eslint', 'prettier'},
  typescriptreact = {'eslint', 'prettier'},
  javascriptreact = {'eslint', 'prettier'},
  json = {'jq'},
  rust = 'rustfmt',
  go = 'gofmt',
  lua = {'lua-format'}
}

vim.g.ale_linters = {
  typescript = {'tsserver', 'tslint'},
  javascript = {'eslint'},
  typescriptreact = {'tslint', 'eslint'},
  javascriptreact = {'eslint'},
  json = {'jq'},
  rust = {'cargo', 'rls'},
  go = {'gofmt'},
  lua = {'lua_language_server'},
}

vim.g.ale_set_quickfix = 1
vim.g.ale_cache_executable_check_failures = 1
