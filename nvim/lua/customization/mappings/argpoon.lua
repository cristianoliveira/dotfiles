local argpoon = require('customization.plugins.argpoon')

vim.keymap.set('n', '<leader>haa', function()
  argpoon.add_file()
end, { desc = '[H]arpoon [A]rgslist [A]dd current selected line' })

local range = {
  [1] = '<leader>h',
  [2] = '<leader>h',
  [3] = '<leader>h',
  [4] = '<leader>h',
}

for i = 1, 4 do
  local shortcut = range[i]..i
  vim.keymap.set('n', shortcut, function()
    argpoon.goto_file(i)
  end, { desc = 'Go to [H]arpoon ' .. i })
end

for i = 1, 4 do
  local shortcut = range[i]..'d'..i
  vim.keymap.set('n', shortcut, function()
    argpoon.delete_file(i)
  end, { desc = '[H]arpoon [D]elete ' .. i })
end

vim.keymap.set('n', '<leader>hs', function()
  argpoon.show_files()
end, { desc = 'Show [H]arpoon [S]tored files' })

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

