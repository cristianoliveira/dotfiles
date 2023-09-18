vim.g.ackprg = "rg --vimgrep --no-heading"

vim.keymap.set('n', '<leader>gg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
-- vim.keymap.set('n', '<leader>gg', ':Ack! ""<Left>', { script = true })
vim.keymap.set('n', '<leader>k', ':Ack! <CR>', { script = true })
