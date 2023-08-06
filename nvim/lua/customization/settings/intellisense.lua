local cmp = require('cmp')

vim.keymap.set('i', '<C-k>', function()
  if cmp.visible() then
    cmp.select_prev_item()
  else
    cmp.complete();
  end
end, { noremap = true })

vim.keymap.set('i', '<C-j>', function()
  if cmp.visible() then
    cmp.select_next_item()
  end
end, { noremap = true })


