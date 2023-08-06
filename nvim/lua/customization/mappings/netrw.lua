-- Mapping when Explorer is open
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('netrw_mapping', {}),
  pattern = 'netrw',
  callback = function()
    local buffer = vim.api.nvim_get_current_buf()
    vim.keymap.set('n', 'u', '-^', { buffer = buffer, remap = true })
    vim.keymap.set('n', 'mm', 'R', { buffer = buffer, remap = true })
    vim.keymap.set('n', 'md', 'D', { buffer = buffer, remap = true })
    vim.keymap.set('n', '<C-r>', '<C-l>', { buffer = buffer, noremap = true })
    vim.keymap.set('n', '<C-l>', '<C-W><C-l>', { buffer = buffer, noremap = true })
    vim.keymap.set('n', 'dd', 'D', { buffer = buffer, remap = true })
    vim.keymap.set('n', '<leader>dd', function()
      vim.cmd('silent! call netrw#NetrwDelete()')
    end, { buffer = buffer, remap = true })
  end,
})

-- Folder navigation
-- Open Ex in the current file dir
nmap('<leader>ee', ':e <C-R>=expand("%:p:h") . "/" <CR><CR>')
-- Open Ex in the project root folder
nmap('<leader>er', ':e . <CR>')

-- Fd specific filders
nmap('<leader>FA', ':Fd api')
nmap('<leader>FM', ':Fd modules')
nmap('<leader>FC', ':Fd components')
nmap('<leader>FL', ':Fd libs')
