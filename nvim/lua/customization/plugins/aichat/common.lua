local M = {}

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

return M
