-- Mapping when Explorer is open
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('netrw_mapping', {}),
  pattern = 'netrw',
  callback = function()
    local buffer = vim.api.nvim_get_current_buf()
    vim.keymap.set('n', '<C-u>', '-^', { buffer = buffer, remap = true })
    vim.keymap.set('n', 'mm', 'R', { buffer = buffer, remap = true })
    vim.keymap.set('n', 'md', 'D', { buffer = buffer, remap = true })
    vim.keymap.set('n', '<C-r>', '<C-l>', { buffer = buffer, noremap = true })
  end,
})

-- Folder navigation
-- Open Ex in the current file dir
nmap('<C-e>', ':e <C-R>=expand("%:p:h") . "/" <CR>')
-- Open Ex in the project root folder
nmap("<C-e>~", ":e . <CR>")
nmap('<leader>e', ':e <C-R>=expand("%:p:h") . "/" <CR>')

-- Fd specific filders
nmap('<leader>FA', ':Fd api')
nmap('<leader>FM', ':Fd modules')
nmap('<leader>FC', ':Fd components')
nmap('<leader>FL', ':Fd libs')
