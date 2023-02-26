-- Panel splitting
nmap("<Leader>s",":split<CR><C-K>")
nmap("<Leader>w",":split<CR>")
nmap("<Leader>v",":vsplit<CR>")

-- Panel navigation with Vim j/k/l/h
nnoremap("<C-J>","<C-W><C-J>")
nnoremap("<C-K>","<C-W><C-K>")
nnoremap("<C-L>","<C-W><C-L>")
nnoremap("<C-H>","<C-W><C-H>")

-- Close quickfix panel
nnoremap("<C-w>w", ":ccl<CR>")

-- Move half page (d)own or (u)p centralizing the window
nnoremap("<C-d>", "<C-d>zz")
nnoremap("<C-u>", "<C-u>zz")
