-- builtin mappings but without overwritting the default register
vim.keymap.set("x", "<leader>P", "\"_dP")
nmap("<leader>d", "\"_d")
vmap("<leader>d", "\"_d")
nmap("<leader>d", "\"_c")
vmap("<leader>d", "\"_c")

-- system clipboard
vmap('<Leader>y', '"+y')
vmap('<C-c>', '"+y') -- Ctrl-C to copy to system clipboard in visual mode
-- FIXME In quarentine delete if not missed.
-- vmap <Leader>d "+d
-- nmap <Leader>p "+p
