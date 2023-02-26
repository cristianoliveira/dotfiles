"Paste mode toggle
set pastetoggle=<F5><F5>

"Kee p selection after indent

nmap <Leader>ob :vert sb
nmap <c-e> :e . <CR>
map <leader>e :e <C-R>=expand("%:p:h") . "/" <CR>
map <leader>t :tabe <C-R>=expand("%:p:h") . "/" <CR>
map <leader>s :split <C-R>=expand("%:p:h") . "/" <CR>

nnoremap <Leader>bn :bnext<CR>
nnoremap <Leader>bp :bprevious<CR>

noremap <silent> <leader>nf :set nofoldenable<CR>

noremap <silent> <leader>cm :let @+ = v:statusmsg<CR>
