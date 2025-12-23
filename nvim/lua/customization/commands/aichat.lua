local runner = require("customization.utils.runner")
local common = require("customization.plugins.aichat.common")

-- ignore commands if aichat is not present
local ainchat_bin = vim.g.aichat_bin or "aichat"
if not vim.fn.executable(ainchat_bin) then
  print("aichat command not found, skipping commands")
  return
end

-- AIMacro module
local M = {}

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

--- AIRefactor command
--
-- This commands receives the file path and optional the lines selected
-- If no lines are selected, it will consider the whole file
--
-- Args:
--  instruction: The instruction to for the refactoring, if not provided it will
--  refactor in a more readable way
--
-- Context Args:
--  filepath: The path to the file to refactor (get from current buffer)
--  lines: The lines to refactor (get from current selection see method above
--
-- Description:
-- Runs the command `aichat -f <filepath> --code <instruction>` with the given instruction
-- and inserts the output into the current line.
vim.api.nvim_create_user_command("AIRefactor", function(opts)
  local instruction = table.concat(opts.fargs or {}, " ")
  if instruction == "" then
    instruction = "Refactor this code to improve readability."
  end

  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" then
    print("Cannot refactor: buffer has no file path")
    return
  end
  local filepath = vim.fn.fnamemodify(buf_name, ":p")

  local selection = common.get_selection()
  local start_line, end_line
  if selection then
    start_line, end_line = selection.start_line, selection.end_line
  elseif opts.range and opts.range > 0 and (opts.line1 ~= opts.line2 or opts.range > 1) then
    start_line, end_line = opts.line1, opts.line2
  else
    start_line, end_line = 1, vim.api.nvim_buf_line_count(0)
  end

  local target_start = start_line - 1
  local target_end = end_line
  local buffer_line_count = vim.api.nvim_buf_line_count(0)
  local range_hint = ""
  if start_line ~= 1 or end_line ~= buffer_line_count then
    range_hint = string.format(" (lines %d-%d)", start_line, end_line)
  end

  local cmd = string.format(
    "%s -r code-patch -f %s --code %s | tee %s",
    vim.fn.shellescape(ainchat_bin),
    vim.fn.shellescape(filepath),
    vim.fn.shellescape(instruction .. range_hint),
    vim.fn.shellescape(filepath..".new")
  )
  print("Running command: " .. cmd)


  local jobid = runner.async({
    "sh",
    "-c",
    cmd
  }, {
    on_error = function(err)
      print(err)
      vim.notify("AIRefactor finished" , vim.log.levels.INFO)
    end,
    on_success = function(code, lines)
      vim.schedule(function()
        if code ~= 0 then
          vim.notify(("AIRefactor failed (code %d): %s"):format(code, res.stderr or ""), vim.log.levels.ERROR)
          return
        end
        vim.notify("AIRefactor finished" , vim.log.levels.INFO)

        vim.cmd("tabnew " .. vim.fn.fnameescape(filepath))
        vim.cmd("vert diffsplit " .. vim.fn.fnameescape(filepath .. ".new"))
      end)
    end
  })

  vim.notify(
    ("AIRefactor started (job %d) it will open once its done..."):format(jobid.pid),
    vim.log.levels.INFO
  )
end, {
  -- allow zero or more instruction arguments
  nargs = "*",
  range = "%",
})

vim.api.nvim_create_user_command("AIRefactorCleanup", function()
  local state = common.last_refactor_patch
  if not state then
    print("No AIRefactor state to clean.")
    return
  end

  common.close_last_refactor_diff()

  local removed = {}
  local failed = {}

  local function try_delete(path)
    if not path or path == "" then
      return
    end
    if vim.fn.filereadable(path) == 1 then
      local ok, err = pcall(vim.fn.delete, path)
      if ok and err == 0 then
        table.insert(removed, path)
      else
        table.insert(failed, path .. (err and (" (" .. tostring(err) .. ")") or ""))
      end
    end
  end

  try_delete(state.patchfile)
  try_delete(state.newfile)

  common.store_last_refactor_patch(nil)

  if #removed > 0 then
    print("AIRefactor cleanup removed: " .. table.concat(removed, ", "))
  end
  if #failed > 0 then
    print("AIRefactor cleanup failed to remove: " .. table.concat(failed, ", "))
  end
  if #removed == 0 and #failed == 0 then
    print("AIRefactor cleanup: nothing to remove.")
  end
end, {
  nargs = 0,
})
