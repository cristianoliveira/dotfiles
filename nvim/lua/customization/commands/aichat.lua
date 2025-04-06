local runner = require("customization.utils.runner")

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
  local macro_cmd = string.format("aichat --macro %s", macro)

  -- Execute command and get the output lines
  local lines = runner.execute(macro_cmd)

  -- Insert lines at the current cursor position
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end, {
  nargs = 1,
  complete = function()
    return runner.execute("aichat --list-macros")
  end
})
