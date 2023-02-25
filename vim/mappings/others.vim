nnoremap <silent> <Leader>sw :call WindowSwap#EasyWindowSwap()<CR>
nmap <Leader>` :call WindowSwap#EasyWindowSwap()<CR><Leader>[:call WindowSwap#EasyWindowSwap()<CR>

map <leader>8 :noh <CR>

"for unhighlighing the selections
nmap <Leader>x :let @/=''<CR>

"split switch
nnoremap <Leader>[ <C-W>w

"Keep the cursor in the same place after yank
vmap y ygv<Esc>

"Reload vimrc

"Paste mode toggle
set pastetoggle=<F5><F5>

"Kee p selection after indent
vnoremap > ><CR>gv
vnoremap < <<CR>gv

" "Camel case motion (with shift)
" map <Leader>w <Plug>CamelCaseMotion_w
map <Leader>b <Plug>CamelCaseMotion_b
map <Leader>e <Plug>CamelCaseMotion_e

nmap <Leader>ob :vert sb
nmap <c-e> :e . <CR>
map <leader>e :e <C-R>=expand("%:p:h") . "/" <CR>
map <leader>t :tabe <C-R>=expand("%:p:h") . "/" <CR>
map <leader>s :split <C-R>=expand("%:p:h") . "/" <CR>

nnoremap <Leader>bn :bnext<CR>
nnoremap <Leader>bp :bprevious<CR>

noremap <silent> <leader>nf :set nofoldenable<CR>

noremap <silent> <leader>cm :let @+ = v:statusmsg<CR>
