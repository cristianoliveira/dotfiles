local s = require('customization.functions.selection')

function Grepapp(args)
  io.popen("open https://grep.app/search?q=" .. args)
end

vim.keymap.set('v', '<leader>ga', function()
  Grepapp(s.selected_text())
end, { noremap = true, silent = true, desc = 'Search [G]rep [A]pp for selected text' })

vim.cmd("command! -nargs=1 Grepapp lua Grepapp(<f-args>)")
