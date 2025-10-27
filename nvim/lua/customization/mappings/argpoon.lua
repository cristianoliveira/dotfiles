local argpoon = require('customization.plugins.argpoon')

vim.keymap.set('n', '<leader>han', function()
  argpoon.add_file()
end, { desc = 'Add file to [H]arpoon [A]rgslist [N]ext' })

vim.keymap.set('n', '<leader>hah', function()
  argpoon.add_file_to_index(1)
end, { desc = 'Add file to [H]arpoon [A]rgslist at [1][H]' })

vim.keymap.set('n', '<leader>haj', function()
  argpoon.add_file_to_index(2)
end, { desc = 'Add file to [H]arpoon [A]rgslist at [2][J]' })

vim.keymap.set('n', '<leader>hak', function()
  argpoon.add_file_to_index(3)
end, { desc = 'Add file to [H]arpoon [A]rgslist at [3][K]' })

vim.keymap.set('n', '<leader>hal', function()
  argpoon.add_file_to_index(4)
end, { desc = 'Add file to [H]arpoon [A]rgslist at [4][L]' })

vim.keymap.set('n', '<leader>hs', function()
  argpoon.show_files()
end, { desc = 'Show [H]arpoon [S]tored files' })

vim.keymap.set('n', '<leader>hh', function()
  argpoon.goto_file(1)
end, { desc = 'Go to [H]arpoon [H]1' })

vim.keymap.set('n', '<leader>hj', function()
  argpoon.goto_file(2)
end, { desc = 'Go to [H]arpoon [J]2' })

vim.keymap.set('n', '<leader>hk', function()
  argpoon.goto_file(3)
end, { desc = 'Go to [H]arpoon [K]3' })

vim.keymap.set('n', '<leader>hl', function()
  argpoon.goto_file(4)
end, { desc = 'Go to [H]arpoon [L]4' })

vim.keymap.set('n', '<leader>hdh', function()
  argpoon.delete_file(1)
end, { desc = 'Delete [H]arpoon [D]1' })

vim.keymap.set('n', '<leader>hdj', function()
  argpoon.delete_file(2)
end, { desc = 'Delete [H]arpoon [D]2' })

vim.keymap.set('n', '<leader>hdk', function()
  argpoon.delete_file(3)
end, { desc = 'Delete [H]arpoon [D]3' })

vim.keymap.set('n', '<leader>hdl', function()
  argpoon.delete_file(4)
end, { desc = 'Delete [H]arpoon [D]4' })

-- List in telescope
-- Collect argslist files
-- Show in telescope picker
vim.keymap.set('n', '<leader>ht', function()
  local argslist = vim.fn.argv()
  if #argslist == 0 then
    print("Argslist is empty.")
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = 'Harpoon Argslist',
    finder = finders.new_table {
      results = argslist,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd("silent! " .. selection.index .. "argument")
        print("Switched to file: " .. selection.value)
      end)
      return true
    end,
  }):find()
end, { desc = 'Telescope [H]arpoon [T]oggle' })

