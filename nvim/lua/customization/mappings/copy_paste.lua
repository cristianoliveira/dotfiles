-- builtin mappings but without overwritting the default register
vim.keymap.set("x", "<leader>P", "\"_dP")
nmap("<leader>d", "\"_d")
vmap("<leader>d", "\"_d")
nmap("<leader>d", "\"_c")
vmap("<leader>d", "\"_c")

-- system clipboard
vmap('<Leader>y', '"+y')
nmap('<Leader>p', '"+p') -- paste from system clipboard
vmap('<Leader>p', '"+p')

-- FIXME In quarentine delete if not missed.
-- vmap <Leader>d "+d
