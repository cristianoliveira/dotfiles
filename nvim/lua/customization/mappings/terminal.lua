-- Terminal-only mappings that avoid codex-cli key conflicts
local term_group = vim.api.nvim_create_augroup('TerminalMappings', { clear = true })
vim.api.nvim_create_autocmd('TermOpen', {
  group = term_group,
  pattern = 'term://*',
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }

    -- Use <C-n> instead of <Esc> to leave terminal-mode without stealing <Esc> from CLI apps
    vim.keymap.set('t', '<C-n>', [[<C-\><C-n>]], opts)

    -- Split navigation with arrows to stay off common shell shortcuts
    vim.keymap.set('t', '<C-Left>', [[<C-\><C-n><C-w>h]], opts)
    vim.keymap.set('t', '<C-Down>', [[<C-\><C-n><C-w>j]], opts)
    vim.keymap.set('t', '<C-Up>', [[<C-\><C-n><C-w>k]], opts)
    vim.keymap.set('t', '<C-Right>', [[<C-\><C-n><C-w>l]], opts)

    -- Close the current terminal window
    vim.keymap.set('t', '<C-q>', [[<C-\><C-n><C-w>q]], opts)
  end,
})

-- Open a horizontal terminal and jump straight into insert mode
vim.keymap.set('n', '<leader>ts', '<cmd>split | term<CR>i', { desc = '[T]erminal [S]plit' })
