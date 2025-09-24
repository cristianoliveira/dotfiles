local M = {}
-- print("Loading aichat.nvim")

-- List your local code agents here so :AICodeAgent offers them as completions.
local code_agent_suggestions = {
  "codex",
  "cursor-agent",
  "claude-code",
  "crush",
  -- Add more entries, e.g. "windsurf", "claude", etc.
}

local function complete_code_agent(arg_lead)
  local matches = {}
  for _, agent in ipairs(code_agent_suggestions) do
    if vim.startswith(agent, arg_lead) then
      table.insert(matches, agent)
    end
  end
  return matches
end

local function get_selection()
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

local function get_selected_text()
  local selection = get_selection()
  if not selection then
    return nil
  end
  return selection.text
end

local function resolve_executable(global_key, fallback)
  local override = vim.g[global_key]
  local executable = override ~= nil and override or fallback
  return vim.fn.executable(executable) == 1, executable
end

function M.send_to_aichat(prompt)
  if not prompt or prompt == "" then
    print("Please provide a prompt")
    return
  end

  local available, bin = resolve_executable("aichat_bin", "aichat")
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

local function resolve_agent_executable(agent_label)
  if not agent_label or agent_label == "" then
    return false, ""
  end

  local sanitized = agent_label:gsub("[^%w_]", "_")
  local candidate_keys = {
    sanitized .. "_bin",
    agent_label ~= sanitized and (agent_label .. "_bin") or nil,
    "aichat_" .. sanitized .. "_bin",
  }

  local override_miss
  for _, key in ipairs(candidate_keys) do
    if key then
      local override = vim.g[key]
      if type(override) == "string" and override ~= "" then
        if vim.fn.executable(override) == 1 then
          return true, override
        end
        override_miss = override_miss or override
      end
    end
  end

  if vim.fn.executable(agent_label) == 1 then
    return true, agent_label
  end

  return false, override_miss or agent_label
end

function M.start_agent_session(agent_label, prompt)
  if not prompt or prompt == "" then
    print("Please provide a prompt")
    return
  end

  local available, bin = resolve_agent_executable(agent_label)
  if not available then
    print(string.format("%s command not found (tried '%s'), skipping agent startup", agent_label, bin))
    return
  end

  local command = { bin }
  if prompt ~= "" then
    table.insert(command, prompt)
  end

  local original_win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  local agent_win = vim.api.nvim_get_current_win()

  vim.cmd("enew")
  local term_buf = vim.api.nvim_get_current_buf()
  vim.bo[term_buf].buflisted = false

  local job_id = vim.fn.termopen(command)
  if job_id <= 0 then
    print(string.format("Failed to start %s agent", agent_label))
    vim.api.nvim_win_close(agent_win, true)
    vim.api.nvim_set_current_win(original_win)
    return
  end

  vim.cmd("startinsert")
  print(string.format("Started %s agent in terminal split", agent_label))
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

vim.api.nvim_create_user_command("AIAgent", function(opts)
  local fargs = opts.fargs or {}
  local agent_label = fargs[1] or ""
  if agent_label == "" then
    print("Please provide a code agent suggestion, e.g. :AICodeAgent codex implement feature")
    return
  end

  local instructions = {}
  for i = 2, #fargs do
    instructions[#instructions + 1] = fargs[i]
  end
  local instruction = table.concat(instructions, " ")
  if instruction == "" then
    print("Please provide instructions after the agent suggestion, e.g. :AICodeAgent codex implement feature")
    return
  end

  local buf_name = vim.api.nvim_buf_get_name(0)
  local resolved_path = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":p") or "[No file path]"

  local selection = get_selection()
  local filetype = vim.bo.filetype
  if filetype == nil or filetype == "" then
    filetype = "text"
  end

  local prompt_parts = {
    "Start a Codex-style code agent session.",
    "\nTarget file: ", resolved_path,
    "\nSelected code agent: ", agent_label,
    "\nInstructions: ", instruction,
    "\nRespond with a clear plan, any clarifying questions, and proposed changes referencing the target file."
  }

  if selection then
    local line_info
    if selection.start_line == selection.end_line then
      line_info = string.format("\nSelected line: %d", selection.start_line)
    else
      line_info = string.format("\nSelected lines: %d-%d", selection.start_line, selection.end_line)
    end
    table.insert(prompt_parts, line_info)

    local selected_text = selection.text or ""
    if selected_text ~= "" then
      table.insert(prompt_parts, string.format("\nSelected code:\n```%s\n%s\n```\n", filetype, selected_text))
    end
  end

  local prompt = table.concat(prompt_parts)

  M.start_agent_session(agent_label, prompt)
end, {
  nargs = "+",
  range = "%",
  complete = function(arg_lead, cmd_line, _)
    local parts = vim.split(cmd_line, "\\s+", { trimempty = true })
    if #parts <= 1 then
      return complete_code_agent(arg_lead)
    end
    if #parts == 2 and cmd_line:sub(-1) ~= " " then
      return complete_code_agent(arg_lead)
    end
    return {}
  end,
})

return M
