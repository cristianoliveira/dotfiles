" Write this in your vimrc file
let g:ale_lint_on_text_changed = 'never'
" You can disable this option too
" if you don't want linters to run on opening a file
let g:ale_lint_on_enter = 0
let b:ale_lint_on_enter = 0

" let g:ale_linters_explicit = 1
" let b:ale_fixers = ['prettier', 'eslint', 'flake8', 'rustc', 'rustfmt', 'gofmt']

" let g:ale_set_quickfix = 1
let g:ale_cache_executable_check_failures = 1

nmap <silent> <leader>aj :ALENext<cr>
nmap <silent> <leader>ak :ALEPrevious<cr>
