vim.keymap.set('i', '<C-q>', function() 
  require("copilot.suggestion").next()
end, { expr = true, script = true })

vim.keymap.set('n', '<leader>cp', function()
  vim.cmd('Copilot')
end, { noremap=true, silent=true })
