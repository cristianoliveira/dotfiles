local opts = { noremap = true, silent = true }

-- Diff mode mappings (when in diff mode)
vim.keymap.set('n', '<leader>dfg', ':diffget<CR>', { desc = 'Diff get (accept change from other buffer)' })
vim.keymap.set('n', '<leader>dfp', ':diffput<CR>', { desc = 'Diff put (send change to other buffer)' })
vim.keymap.set('n', '<leader>dfu', ':diffupdate<CR>', { desc = 'Update diff highlighting' })

-- Three-way merge helpers (useful with git mergetool)
vim.keymap.set('n', '<leader>dfl', ':diffget LOCAL<CR>', { desc = 'Get LOCAL change (current branch)' })
vim.keymap.set('n', '<leader>dfr', ':diffget REMOTE<CR>', { desc = 'Get REMOTE change (incoming branch)' })
vim.keymap.set('n', '<leader>dfb', ':diffget BASE<CR>', { desc = 'Get BASE change (common ancestor)' })

-- Close all diff windows except current
vim.keymap.set('n', '<leader>dfq', ':diffoff!<CR>', { desc = 'Close all diff windows' })
