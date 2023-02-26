set wildignore+=*/.git/*,*/tmp/*,*.swp

let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

" Default to filename searches - so that appctrl will find application
" controller
let g:ctrlp_by_filename = 1

" Don't jump to already open window. This is annoying if you are maintaining
" several Tab workspaces and want to open two windows into the same file.
let g:ctrlp_switch_buffer = 0

" Cmd-Shift-P to clear the cache
nnoremap <silent> <D-P> :ClearCtrlPCache<cr>
nnoremap <D-B> :CtrlPBuffer

" Idea from : http://gdwww.charlietanksley.net/blog/blog/2011/10/18/vim-navigation-with-lustyexplorer-and-lustyjuggler/
" Open CtrlP starting from a particular path, making it much
" more likely to find the correct thing first. mnemonic 'jump to [something]'
nmap <Leader>pp :CtrlP<CR>
nmap <Leader>pb :CtrlPBuffer<CR>
nmap <Leader>fb :CtrlPBuffer<CR>
nmap <Leader>fl :CtrlPLine<CR>
nmap <leader>ft :CtrlPTag<CR>

" Rails
map <leader>fa :CtbrlP app/assets<CR>
map <leader>fm :CtrlP app/models<CR>
map <leader>fc :CtrlP app/controllers<CR>
map <leader>fv :CtrlP app/views<CR>
map <leader>fj :CtrlP app/assets/javascripts<CR>
map <leader>fs :CtrlP spec<CR>

nmap <c-b> :CtrlPBuffer<CR>
vmap <c-b> :CtrlPBuffer<CR>
