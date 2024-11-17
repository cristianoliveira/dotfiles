vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

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

nnoremap("<leader>R", ":source ~/.vimrc<CR>")

-- Remap only for command mode to navigate with hjkl
vim.keymap.set({ 'c' }, "<C-h>", "<Left>")
vim.keymap.set({ 'c' }, "<C-j>", "<Down>")
vim.keymap.set({ 'c' }, "<C-k>", "<Up>")
vim.keymap.set({ 'c' }, "<C-l>", "<Right>")

-- :W does the same as :w I keep messing up the shift key
vim.cmd("command! -nargs=0 W w")
vim.cmd("command! -nargs=0 WQ wq")
vim.cmd("command! -nargs=0 Wq wq")
