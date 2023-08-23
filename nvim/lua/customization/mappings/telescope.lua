-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
        ["<C-i>"] = require('telescope.actions').select_default,
        ["<C-n>"] = require('telescope.actions').cycle_history_next,
        ["<C-p>"] = require('telescope.actions').cycle_history_prev,
        ["<C-k>"] = {
          require('telescope.actions').move_selection_previous, type = "action",
          opts = { nowait = true, silent = true }
        },
        ["<C-j>"] = {
          require('telescope.actions').move_selection_next, type = "action",
          opts = { nowait = true, silent = true }
        },
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<C-b>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })

vim.keymap.set('n', '<C-p>', require('telescope.builtin').find_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })

vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sk', require('telescope.builtin').keymaps, { desc = '[S]earch [K]Keymaps' })
vim.keymap.set('n', '<leader>st', ":lua require('telescope.builtin')", { desc = 'Prepare [S]earch command for [T]elescope' })

vim.keymap.set('v', '<leader>k', function()
  vim.cmd.normal('"ky')
  require('telescope.builtin').grep_string({ search = vim.fn.getreg('k') })
end, { script = true, desc = 'Mimic "Ac[K]" behaviour by searching the selected text' })

vim.keymap.set('n', '<leader>k', function()
  require('telescope.builtin').grep_string({ search = vim.fn.expand("<cword>") })
end, { script = true, desc = 'Mimic "Ac[K]" behaviour by searching the selected text' })

vim.keymap.set('n', '<leader>gg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
