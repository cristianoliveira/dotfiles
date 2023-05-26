"<LeftMouse> REPLACE SEARCH IN ALL FILES LISTED IN QUICK FIX
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


function! s:Camelize(range) abort
  if a:range == 0
    s#\(\%(\<\l\+\)\%(_\)\@=\)\|_\(\l\)#\u\1\2#g
  else
    s#\%V\(\%(\<\l\+\)\%(_\)\@=\)\|_\(\l\)\%V#\u\1\2#g
  endif
endfunction

function! s:Snakeize(range) abort
  if a:range == 0
    s#\C\(\<\u[a-z0-9]\+\|[a-z0-9]\+\)\(\u\)#\l\1_\l\2#g
  else
    s#\%V\C\(\<\u[a-z0-9]\+\|[a-z0-9]\+\)\(\u\)\%V#\l\1_\l\2#g
  endif
endfunction

command! -range CamelCase silent! call <SID>Camelize(<range>)
command! -range SnakeCase silent! call <SID>Snakeize(<range>)
