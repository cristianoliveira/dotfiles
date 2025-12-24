local argpoon = require('customization.plugins.argpoon')
local fn = require('customization.utils.fn')

vim.keymap.set('n', '<leader>haa', function()
  argpoon.add_file()
end, { desc = '[H]arpoon [A]rgslist [A]dd current selected line' })

local mappings = {
  [1] = '<leader>h',
  [2] = '<leader>h',
  [3] = '<leader>h',
  [4] = '<leader>h',
}

fn.for_each(mappings, function(mapping, idx)
  -- <leader>h<n> to go to file
  local shortcut = mapping..idx
  vim.keymap.set('n', shortcut, function()
    argpoon.goto_file(idx)
  end, { desc = 'Go to [H]arpoon ' .. idx })

  -- <leader>hd<n> to delete
  local delete_shortcut = mapping..'d'..idx
  vim.keymap.set('n', delete_shortcut, function()
    argpoon.delete_file(idx)
  end, { desc = '[H]arpoon [D]elete ' .. idx })
end)

vim.keymap.set('n', '<leader>hs', function()
  argpoon.show_files()
end, { desc = 'Show [H]arpoon [S]tored files' })

-- List in telescope
-- Collect argslist files
-- Show in telescope picker
vim.keymap.set('n', '<leader>ht', function()
  local argslist = argpoon.get_files()
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

