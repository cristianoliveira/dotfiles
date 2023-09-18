local M = {}

M.selected_text = function()
  vim.cmd.normal('"gy')
  return vim.fn.getreg('g')
end

return M
