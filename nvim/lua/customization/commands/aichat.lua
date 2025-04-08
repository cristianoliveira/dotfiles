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

  -- Execute command and get the output lines
  local lines = fn.filter(runner.execute(macro_cmd), function(line)
    return not string.match(line, ">>")
  end)

  -- Insert lines at the current cursor position
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end, {
  -- it may contain 1 or more arguments
  nargs = "*",
  complete = function()
    return runner.execute("aichat --list-macros")
  end
})
