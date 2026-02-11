-- Clipboard commands --

-- Select among these types to copy:
local types = {
  "file_path",
  "file_relative_path",
  "file_name",
  "directory_path",
  "directory_relative_path",
  "directory_name"
}
vim.api.nvim_create_user_command('Cpb', function(opts)
  local type = opts.args
  local start_line = opts.line1
  local end_line = opts.line2
  local has_selection = opts.range and opts.range > 0
  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)

  local result = ""

  if type == "file_path" then
    result = file_path
  elseif type == "file_relative_path" then
    result = vim.fn.fnamemodify(file_path, ":~:.")
  elseif type == "file_name" then
    result = vim.fn.fnamemodify(file_path, ":t")
  elseif type == "directory_path" then
    result = vim.fn.fnamemodify(file_path, ":h")
  elseif type == "directory_relative_path" then
    local dir = vim.fn.fnamemodify(file_path, ":h")
    result = vim.fn.fnamemodify(dir, ":~:.")
  elseif type == "directory_name" then
    result = vim.fn.fnamemodify(file_path, ":h:t")
  end

  if has_selection then
    if start_line ~= end_line then
      result = result .. "#" .. start_line .. "-" .. end_line
    else
      result = result .. "#" .. start_line
    end
  end

  vim.fn.setreg("+", result)
  vim.notify("Copied to clipboard: " .. result, vim.log.levels.INFO)
end, {
  nargs = 1,
  range = 2,
  complete = function()
    return types
  end
})

