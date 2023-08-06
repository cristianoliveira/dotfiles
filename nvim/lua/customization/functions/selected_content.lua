-- vim function to get the selected content (only one line)
local function get_selected_content()
  local line1 = vim.fn.getpos("'<")[2]
  local col1 = vim.fn.getpos("'<")[3]
  local line2 = vim.fn.getpos("'>")[2]
  local col2 = vim.fn.getpos("'>")[3]
  local lines = vim.fn.getline(line1, line2)

  if #lines == 0 then
    return nil
  end

  if #lines > 1 then
    error("get_selected_content only works with one line selection")
  end

  local selected = string.sub(lines[1], col1, col2)

  if #selected < 3 then
    return nil
  end

  return selected
end

return get_selected_content
