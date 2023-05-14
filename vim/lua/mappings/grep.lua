vim.g.ackprg = "rg --vimgrep --no-heading"

vim.keymap.set('v', '<leader>k', function()
  local content = require"functions/selected_content"()
  if content == nil or content == '' then
    return
  end

  vim.cmd("Ack " .. content .. " .")
end, { silent = true })

vim.keymap.set('n', '<leader>gg', ':Ack! ""<Left>', { silent = true })
vim.keymap.set('n', '<leader>k', ':Ack! <CR>', { silent = true })
