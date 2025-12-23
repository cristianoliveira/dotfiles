local M = {
  get_selection = nil,
  complete_code_agent = nil,
  last_refactor_patch = nil,
}

---@alias SelectionResult {text: string, start_line: number, end_line: number, mode: string}
---Get the currently selected text in visual mode
---@return SelectionResult|nil selection The selection result or nil if no selection
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

---Completion function for code agent command argument
---@param arg_lead string The leading portion of the argument being completed
---@return string[] matches List of matching code agent suggestions
M.complete_code_agent = function (arg_lead)
  local code_agent_suggestions = {
    "codex",
    "cursor-agent",
    "claude-code",
    "crush",
    -- Add more entries, e.g. "windsurf", "claude", etc.
  }
  local matches = {}
  for _, agent in ipairs(code_agent_suggestions) do
    if vim.startswith(agent, arg_lead) then
      table.insert(matches, agent)
    end
  end
  return matches
end

M.close_last_refactor_diff = function()
  local state = M.last_refactor_patch
  if not state then
    return
  end
  if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
    pcall(vim.api.nvim_win_close, state.diff_win, true)
  end
  if state.diff_buf and vim.api.nvim_buf_is_valid(state.diff_buf) then
    vim.api.nvim_buf_delete(state.diff_buf, { force = true })
  end
  M.last_refactor_patch = nil
end

M.store_last_refactor_patch = function(patch_info)
  M.last_refactor_patch = patch_info
end

return M
