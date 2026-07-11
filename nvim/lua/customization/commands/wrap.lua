local M = {}

local function validate_width(width)
  if type(width) ~= "number" or width < 1 or width % 1 ~= 0 then
    error("Wrap width must be a positive integer")
  end
end

function M.current_paragraph(width)
  validate_width(width)

  local previous_width = vim.bo.textwidth
  local view = vim.fn.winsaveview()
  vim.bo.textwidth = width
  vim.cmd("normal! gqap")
  vim.bo.textwidth = previous_width
  vim.fn.winrestview(view)
end

vim.api.nvim_create_user_command("CWrap", function(opts)
  local width = opts.args == "" and 80 or tonumber(opts.args)
  local ok, err = pcall(M.current_paragraph, width)

  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, {
  nargs = "?",
  desc = "Wrap the current paragraph at 80 columns, or the supplied width",
})

return M
