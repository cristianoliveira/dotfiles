vim.keymap.set('i', '<C-q>', function()  vim.fn['copilot#Suggest']() end, { expr = true, script = true })
vim.keymap.set('i', '<C-h>', function()  vim.fn['copilot#Next']() end, { expr = true, script = true })
vim.keymap.set('i', '<C-x>', function()  vim.fn['copilot#Clear']() end, { expr = true, script = true })

-- vim.keymap.set('i', '<C-i>', function()
--   local result = vim.fn['copilot#Accept']("")
--   return string.sub(result, 1, -4) -- strips @7
-- end, { script=true, expr = true })

-- vim map <leader>cp to call command Copilot
vim.keymap.set('n', '<leader>cp', function()
  vim.cmd('Copilot')
end, { noremap=true, silent=true })

-- vim.g.copilot_no_tab_map = true
