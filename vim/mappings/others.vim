"Paste mode toggle
set pastetoggle=<F5><F5>

"Kee p selection after indent

nmap <c-e> :e . <CR>
map <leader>e :e <C-R>=expand("%:p:h") . "/" <CR>
map <leader>s :split <C-R>=expand("%:p:h") . "/" <CR>

noremap <silent> <leader>nf :set nofoldenable<CR>

noremap <silent> <leader>cm :let @+ = v:statusmsg<CR>
