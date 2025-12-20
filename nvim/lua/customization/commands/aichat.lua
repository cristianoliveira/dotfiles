local runner = require("customization.utils.runner")
local fn = require("customization.utils.fn")

-- ignore commands if aichat is not present
local ainchat_bin = vim.g.aichat_bin or "aichat"
if not vim.fn.executable(ainchat_bin) then
  print("aichat command not found, skipping commands")
  return
end

--- AIMacro command
--
-- Args:
--  macro: The name of the macro to run.
--
-- Description:
-- Runs the command `aichat --macro` with the given macro and
-- inserts the output into the current line.
-- Suggest all macros from `aichat --list-macros`
vim.api.nvim_create_user_command("AIMacro", function(opts)
  local macro = opts.fargs[1]
  if not macro or macro == "" then
    print("Please provide a macro name")
    return
  end

  local context = table.concat(opts.fargs, " ", 2)
  local macro_cmd = string.format("aichat -S --macro %s \"%s\"", macro, context)
  print("Running command: " .. macro_cmd)

  local lines = {}
  local row = vim.api.nvim_win_get_cursor(0)[1]
  runner.stream(macro_cmd, function(line)
    if string.match(line, ">>") then
      return
    end
    table.insert(lines, line)
    vim.api.nvim_buf_set_lines(0, row, row + #lines - 1, false, lines)
  end)

  -- Insert lines at the current cursor position
  -- local row = vim.api.nvim_win_get_cursor(0)[1]
  -- vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end, {
  -- it may contain 1 or more arguments
  nargs = "*",
  complete = function(fargs)
    local macro = fargs or ".*"
    return runner.execute("aichat --list-macros | grep " .. macro)
  end
})
