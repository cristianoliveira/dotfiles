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

--- On a random chance open the todo.txt if it is available
local todo_group = vim.api.nvim_create_augroup('OpenTodo', { clear = true })
math.randomseed(os.time())  -- Seed with current time
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.filereadable('todo.txt') == 0 then
      return
    end
    local chance = math.random() <= 0.5
    if chance then
      return
    end
    vim.cmd([[e todo.txt]])
  end,
  group = todo_group,
})

-- format on save using vim.lsp.buf.format()
-- local format_group = vim.api.nvim_create_augroup('FormatOnSave', { clear = true })
-- vim.api.nvim_create_autocmd('BufWritePre', {
--   callback = function()
--     vim.lsp.buf.format()
--   end,
--   group = format_group,
-- })
