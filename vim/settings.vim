" Open the Ag command and place the cursor into the quotes
nmap ,ag :Ag ""<Left>
nmap ,af :AgFile ""<Left>
nmap <C-g> :Ag ""<Left>
nmap <C-f> :AgFile ""<Left>

" Tab Osx Style
nmap <silent> <C-[> :tabprevious<CR>
nmap <silent> <C-]> :tabnext<CR>

" Fuzzy Search
nmap <silent> <C-b> ,b
nmap <silent> <C-t> ,t
nmap T ,t

" Multiple Edition
vmap <C-m> ,mc<cr>

" Clipboard
vmap <C-V> "*y
vmap <leader>y "*y
nmap <leader>p "*p

" Sintax Linters
let g:syntastic_python_checkers = ['flake8']

" NEERDtree
let NERDTreeIgnore = ['\.pyc$', '__pycache__']
let g:nrdtree_tabs_open_on_gui_startup = 1

" Max 80 columns
let &colorcolumn=join(range(81,81),",")

set background=dark
" solarized options
let g:solarized_visibility = "high"
let g:solarized_contrast = "high"
colorscheme solarized

