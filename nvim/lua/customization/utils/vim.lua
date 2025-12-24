local M = {}

M.Buffer = {
  --- Prepend lines at the start of the buffer
  ---@param lines string[] The lines to prepend
  ---@param bufnr? integer The buffer number (defaults to current buffer)
  prepend = function(lines, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
  end,

  --- Append lines at the end of the buffer
  ---@param lines string[] The lines to append
  ---@param bufnr? integer The buffer number (defaults to current buffer)
  append = function(lines, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)
  end
}

return M
