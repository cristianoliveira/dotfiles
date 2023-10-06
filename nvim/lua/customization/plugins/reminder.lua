local s = require('customization.functions.selection')

function Reminder(args)
  print("Sending reminder of: " .. args)
  vim.cmd("!emailme " .. args)
end

vim.keymap.set('v', '<leader>rmt', function()
  Reminder(s.selected_text())
end, { noremap = true, silent = true, desc = '[R]emind [m]e [t]his' })

vim.keymap.set('n', '<leader>rml', function()
  Reminder(vim.fn.getline('.'))
end, { noremap = true, silent = true, desc = '[R]emind [m]e [l]ine' })

vim.cmd("command! -nargs=1 RemindeMe !emailme <f-args>")
