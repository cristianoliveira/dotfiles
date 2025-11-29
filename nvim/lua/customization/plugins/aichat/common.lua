local M = {
  get_selection = nil,
  complete_code_agent = nil,
}

-- List your local code agents here so :AICodeAgent offers them as completions.
local code_agent_suggestions = {
  "codex",
  "cursor-agent",
  "claude-code",
  "crush",
  -- Add more entries, e.g. "windsurf", "claude", etc.
}

M.complete_code_agent = function (arg_lead)
  local matches = {}
  for _, agent in ipairs(code_agent_suggestions) do
    if vim.startswith(agent, arg_lead) then
      table.insert(matches, agent)
    end
  end
  return matches
end

M.get_selection = function ()
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
    return {
      text = table.concat(lines, "\n"),
      start_line = start_line,
      end_line = end_line,
      mode = mode,
    }
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
    return {
      text = table.concat(block_lines, "\n"),
      start_line = start_line,
      end_line = end_line,
      mode = mode,
    }
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

  return {
    text = table.concat(text, "\n"),
    start_line = start_line,
    end_line = end_line,
    mode = mode,
  }
end

return M
