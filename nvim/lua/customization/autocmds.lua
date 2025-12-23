local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

--- trim empty lines at the end of the file
local trim_group = vim.api.nvim_create_augroup('TrimEmptyLines', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    vim.cmd([[silent! %s/\s\+$//e]])
  end,
  group = trim_group,
})

-- format on save using vim.lsp.buf.format()
-- local format_group = vim.api.nvim_create_augroup('FormatOnSave', { clear = true })
-- vim.api.nvim_create_autocmd('BufWritePre', {
--   callback = function()
--     vim.lsp.buf.format()
--   end,
--   group = format_group,
-- })
