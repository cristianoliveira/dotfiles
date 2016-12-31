function! GetVisual()
  let reg_save = getreg('"')
  let regtype_save = getregtype('"')
  let cb_save = &clipboard
  set clipboard&
  normal! ""gvy
  let selection = getreg('"')
  call setreg('"', reg_save, regtype_save)
  let &clipboard = cb_save
  return selection
endfunction

nmap <leader>gg :Ag ""<Left>
nmap <leader>gf :AgFile ""<Left>
vnoremap <leader>gf :<C-U>execute "AgFile " . GetVisual()<CR>

"grep the current word using K (mnemonic Kurrent)
nnoremap <leader>k :Ag <cword><CR>
nnoremap <leader>o :e <cword><CR>

"grep visual selection
vnoremap <leader>k :<C-U>execute "Ag " . GetVisual()<CR>

"grep current word up to the next exclamation point using ,K
nnoremap ,K viwf!:<C-U>execute "Ag " . GetVisual()<CR>

"grep for 'def foo'
noremap <leader>gd :Ag 'def .*<cword>'<CR>
noremap <leader>gc :Ag 'class .*<cword>'<CR>
noremap <leader>gm :Ag 'module .*<cword>'<CR>

",gg = Grep! - using Ag the silver searcher
" open up a grep line, with a quote started for the search

"Grep for usages of the current file
nnoremap ,gcf :exec "Ag " . expand("%:t:r")<CR>

let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

nnoremap ,ag :Ag ""<left>

if exists("g:ctrlp_user_command")
  unlet g:ctrlp_user_command
endif

if executable('ag')
  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command =
    \ 'ag %s --files-with-matches -g "" --ignore "\.git$\|\.hg$\|\.svn$"'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
else
  " Fall back to using git ls-files if Ag is not available
  let g:ctrlp_custom_ignore = '\.git$\|\.hg$\|\.svn$'
  let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files . --cached --exclude-standard --others']
endif

" Default to filename searches - so that appctrl will find application
" controller
let g:ctrlp_by_filename = 1

" Don't jump to already open window. This is annoying if you are maintaining
" several Tab workspaces and want to open two windows into the same file.
let g:ctrlp_switch_buffer = 0

" Cmd-Shift-P to clear the cache
nnoremap <silent> <D-P> :ClearCtrlPCache<cr>

" Idea from : http://www.charlietanksley.net/blog/blog/2011/10/18/vim-navigation-with-lustyexplorer-and-lustyjuggler/
" Open CtrlP starting from a particular path, making it much
" more likely to find the correct thing first. mnemonic 'jump to [something]'
nmap <Leader>tt :CtrlP<CR>
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

