local M = {}
-- print("Loading aichat.nvim")

local function get_selected_text()
  local mode = vim.fn.visualmode()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]

  if start_line == 0 or end_line == 0 then
    return nil
  end

  local start_row = start_line - 1
  local end_row = end_line - 1

  if mode == "V" then
    local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
    if #lines == 0 then
      return nil
    end
    return table.concat(lines, "\n")
  end

  if mode == "\22" then
    -- blockwise visual selection: slice the same column range across all lines
    local col_start = math.max(math.min(start_col, end_col), 1)
    local col_end = math.max(math.max(start_col, end_col), 1)
    local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
    if #lines == 0 then
      return nil
    end
    local block_lines = {}
    for _, line in ipairs(lines) do
      local line_len = #line
      local slice_start = math.min(col_start, line_len + 1)
      local slice_end = math.min(col_end, line_len)
      if slice_start > slice_end then
        block_lines[#block_lines + 1] = ""
      else
        block_lines[#block_lines + 1] = string.sub(line, slice_start, slice_end)
      end
    end
    return table.concat(block_lines, "\n")
  end

  local start_byte = math.max(start_col - 1, 0)
  local last_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1] or ""
  local end_byte = math.max(math.min(end_col, #last_line), 0)
  if end_col >= vim.v.maxcol then
    end_byte = #last_line
  end
  if end_row == start_row and end_byte < start_byte then
    end_byte = start_byte
  end

  local ok, text = pcall(vim.api.nvim_buf_get_text, 0, start_row, start_byte, end_row, end_byte, {})
  if not ok or #text == 0 then
    return nil
  end

  return table.concat(text, "\n")
end

local function is_aichat_available()
  local aichat_bin = vim.g.aichat_bin or "aichat"
  return vim.fn.executable(aichat_bin) == 1, aichat_bin
end

function M.send_to_aichat(prompt)
  if not prompt or prompt == "" then
    print("Please provide a prompt")
    return
  end

  local available, bin = is_aichat_available()
  if not available then
    print("aichat command not found, skipping commands")
    return
  end

  local command = string.format("%s %s", vim.fn.shellescape(bin), vim.fn.shellescape(prompt))
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
  local selected_text = get_selected_text()
  if not selected_text or selected_text == "" then
    print("Please select text in visual mode before calling :AIChatExplain")
    return
  end

  M.send_to_aichat("Given this code: \n```lua\n" .. selected_text .. "\n```\nExplain it in detail.")
end, {
  nargs = 0,
  range = "%"
})

vim.api.nvim_create_user_command("AIRefactor", function(opts)
  local selected_text = get_selected_text()
  if not selected_text or selected_text == "" then
    print("Please select text in visual mode before calling :AIRefactor")
    return
  end

  local instruction = table.concat(opts.fargs or {}, " ")
  if instruction == "" then
    print("Please provide refactor instructions, e.g. :AIRefactor simplify loop")
    return
  end

  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" then
    buf_name = "[No file path]"
  else
    buf_name = vim.fn.fnamemodify(buf_name, ":p")
  end

  local filetype = vim.bo.filetype
  if filetype == nil or filetype == "" then
    filetype = "text"
  end

  local prompt = table.concat({
    "File path: ", buf_name, "\n",
    "Instruction: ", instruction, "\n",
    "Selected code:\n```", filetype, "\n",
    selected_text, "\n```\n",
    "Refactor the selection according to the instruction and respond with the updated code snippet only."
  })

  M.send_to_aichat(prompt)
end, {
  nargs = "+",
  range = "%"
})

return M
