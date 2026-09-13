local M = {}

local function is_absolute(filename)
  local first_character = filename:sub(1, 1)
  local drive_separator = filename:sub(2, 3)

  return first_character == "/"
    or first_character == "\\"
    or drive_separator == ":/"
    or drive_separator == ":\\"
end

local function relative_to_current_file(filename)
  if is_absolute(filename) then
    return filename
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local base_dir = current_file == "" and vim.fn.getcwd() or vim.fn.fnamemodify(current_file, ":h")

  return vim.fn.fnamemodify(base_dir .. "/" .. filename, ":p")
end

function M.under_cursor()
  local filename = vim.fn.expand(vim.fn.expand("<cfile>"))
  vim.cmd("find " .. vim.fn.fnameescape(relative_to_current_file(filename)))
end

return M
