-- AIMacro command
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

  -- Execute command and collect the output
  local handle = io.popen(macro_cmd)
  if handle then
    local result = handle:read("*a")
    handle:close()

    -- Split result into lines
    local lines = {}
    for line in result:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end

    -- Insert lines at the current cursor position
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  end
end, {
  nargs = 1,
  -- function(_arg_lead, cmd_line, cursor_pos)
  complete = function()
    local macros = {}
    local handle = io.popen("aichat --list-macros")
    if handle then
      for line in handle:lines() do
        table.insert(macros, line)
      end
      handle:close()
    end

    return macros
  end
})
