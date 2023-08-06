vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Keep view on the middle of screen to each search
nmap("n", "nzzzv")
nmap("N", "Nzzzv")
nmap("<C-o>", "<C-o>zzzv")
nmap("<C-i>", "<C-i>zzzv")

-- Keep the cursor in the same place after yank
vmap("y", "ygv<Esc>")

-- for unhighlighing the selections
nmap("<leader>8", ":noh<CR>")
nmap("<leader>x", ":let @/=''<CR>")

vnoremap(">", "><CR>gv")
vnoremap("<", "<<CR>gv")

-- Move half page (d)own or (u)p centralizing the window
nnoremap("<C-d>", "<C-d>zz")
nnoremap("<C-u>", "<C-u>zz")

-- nnoremap("<C-p>", ":FZF<CR>")


nnoremap("<leader>R", ":source ~/.vimrc<CR>")

-- Remap only for command mode to navigate with hjkl
vim.keymap.set({ 'c' },"<C-h>", "<Left>")
vim.keymap.set({ 'c' },"<C-j>", "<Down>")
vim.keymap.set({ 'c' },"<C-k>", "<Up>")
vim.keymap.set({ 'c' },"<C-l>", "<Right>")
