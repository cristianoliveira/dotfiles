let g:ackprg = "rg --vimgrep --no-heading"

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


"grep visual selection
vnoremap <leader>k :<C-U>execute "Ack '" . GetVisual() "'"<CR>

"grep current word up to the next exclamation point using ,K
nnoremap ,K viwf!:<C-U>execute "Ag " . GetVisual()<CR>

" SEARCH A TERM AND LIST IN THE QUICK FIX FILES
" ---------------------------------------------

",gg = Grep! - using Ag the silver searcher
" open up a grep line, with a quote started for the search

"Grep for usages of the current file
nnoremap <leader>gcf :exec "Ack " . expand("%:t:r")<CR>

nmap <leader>agj :Ack! js ""<Left>
nmap <leader>ags :Ack! css  ""<Left>
nmap <leader>agr :Ack! rb ""<Left>

nmap <leader>jk :Ack! js <cword><CR>

nmap <leader>gg :Ack! ""<Left>
nnoremap <leader>k :Ack!<CR>
nnoremap <leader>hk :Ack! <C-r>/<CR>

" REPLACE SEARCH IN ALL FILES LISTED IN QUICK FIX
" [R]e[F]actoring
" ---------------------------------------------

nmap <leader>rfe :cfdo %s/<C-r>///g<left><left> | update
nmap <leader>rfc :cfdo %s/<C-r>///gc<left><left><left> | update
nmap <leader>rfd :cfdo %s/<C-r>//<C-r>"/gc | update

" Register the word to be used in the replace
" target
vmap <leader>rft "ty
" replace
vmap <leader>rfr "ry
" Find instances of target
nmap <leader>rff :Ack! <C-r>t<CR>
" Refactoring apply
nmap <leader>rfa :cfdo %s/<C-r>t/<C-r>r/gc | update

" Refactoring searched word
nmap <leader>rfs :cfdo %s/<C-r>//<C-r>r/gc | update

" REPLACE SEARCH IN CURRENT FILE
" [R]eplace [R]egister
" ---------------------------------------------
" Find and Replace
nmap <leader>rr :%s/<C-r>///g<left><left>
vmap <leader>rr :s/<C-r>///g<left><left>
nmap <leader>rc :%s/<C-r>///gc<left><left><left>

nmap <leader>rsr :%s/<C-r>//<C-r>r/gc<left><left>
vmap <leader>rsr :s/<C-r>//<C-r>r/gc<left><left>

