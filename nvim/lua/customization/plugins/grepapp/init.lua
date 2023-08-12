function Grepapp(args)
  io.popen("open https://grep.app/search?q=".. args)
end

function selected_text()
  vim.cmd.normal('"gy')
  return vim.fn.getreg('g')
end

vim.keymap.set('v', '<leader>ga', function()
  Grepapp(selected_text())
end, { noremap = true, silent = true, desc = 'Search [G]rep [A]pp for selected text' })

vim.cmd("command! -nargs=1 Grepapp lua Grepapp(<f-args>)")
