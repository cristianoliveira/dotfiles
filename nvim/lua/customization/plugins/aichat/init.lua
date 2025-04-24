local M = {}
-- print("Loading aichat.nvim")

local function get_selected_text()
  local mode = vim.fn.visualmode()
  local start_line, start_col, end_line, end_col = vim.fn.getpos("'<")[2], vim.fn.getpos("'<")[3], vim.fn.getpos("'>")[2], vim.fn.getpos("'>")[3]
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return ""
  end
  if mode == "V" then
    return table.concat(lines, "\n")
  else
    return lines[1]:sub(start_col, end_col)
  end
end

function M.send_to_aichat(prompt)
  if not prompt or prompt == "" then
    print("Please provide a prompt")
    return
  end

  local command = "aichat \"" .. prompt .. "\""
  -- Exectute and collect the response
  local handle = io.popen(command)
  if handle == nil then
    print("aichat command not found, skipping commands")
    return
  end
  local result = handle:read("*a")
  handle:close()

  print("Aichat response: " .. result)
end

vim.api.nvim_create_user_command("AIChatExplain", function()
  if vim.fn.visualmode() == "v" then
    print("Please select text in visual mode")
    return
  end
  local selected_text = get_selected_text()

  print(get_selected_text())

  M.send_to_aichat("Given this code: \n```lua" .. selected_text .. "\n```, explain it in detail.")
end, { 
  nargs = 0,
  range = "%"
})

return M
