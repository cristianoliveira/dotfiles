local common = require("customization.plugins.aichat.common")

vim.api.nvim_create_user_command("AIResearch", function(opts)
  local fargs = opts.fargs or {}
  local agent_label = fargs[1] or ""
  if agent_label == "" then
    print("Please provide a code agent suggestion, e.g. :AIReaseach codex implement feature")
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
    "Start a code agent session.",
    "\nTarget file: ", resolved_path,
    "\nSelected code agent: ", agent_label,
    "\nInstructions: ", instruction,
    "\nGenerate a doc in the current folder summarizing relevant information of your research.",
    "\n - Include links to sources.",
    "\n - Please include path to the code and relevant info",
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
      return common.complete_code_agent(arg_lead)
    end
    if #parts == 2 and cmd_line:sub(-1) ~= " " then
      return common.complete_code_agent(arg_lead)
    end
    return {}
  end,
})

