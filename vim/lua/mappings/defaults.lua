-- Keep view on the middle of screen to each search
nmap("n", "nzzzv")
nmap("N", "Nzzzv")

-- Keep the cursor in the same place after yank
vmap("y", "ygv<Esc>")

-- for unhighlighing the selections
nmap("<leader>8", ":noh<CR>")
nmap("<Leader>x", ":let @/=''<CR>")

vnoremap(">", "><CR>gv")
vnoremap("<", "<<CR>gv")
