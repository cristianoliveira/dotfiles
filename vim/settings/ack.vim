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

nmap <leader>gg :Ack! ""<Left>

"grep the current word using K (mnemonic Kurrent)
nnoremap <leader>k :Ack! <cword><CR>
nnoremap <leader>o :e <cword><CR>

"grep visual selection
vnoremap <leader>k :<C-U>execute "Ack '" . GetVisual() "'"<CR>

"grep current word up to the next exclamation point using ,K
nnoremap ,K viwf!:<C-U>execute "Ag " . GetVisual()<CR>

",gg = Grep! - using Ag the silver searcher
" open up a grep line, with a quote started for the search

"Grep for usages of the current file
nnoremap <leader>gcf :exec "Ack " . expand("%:t:r")<CR>

nmap <leader>agj :Ack! js ""<Left>
nmap <leader>ags :Ack! css  ""<Left>
nmap <leader>agr :Ack! rb ""<Left>
