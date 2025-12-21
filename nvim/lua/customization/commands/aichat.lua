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
    "%s -f %s --code %s",
    vim.fn.shellescape(ainchat_bin),
    vim.fn.shellescape(filepath),
    vim.fn.shellescape(instruction .. range_hint)
  )
  print("Running command: " .. cmd)

  local lines = runner.execute(cmd)
  if not lines or #lines == 0 then
    print("AIRefactor produced no output")
    return
  end

  local original_file = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local new_file = vim.list_extend({}, original_file)
  for _ = target_start + 1, target_end do
    table.remove(new_file, target_start + 1)
  end
  for idx, line in ipairs(lines) do
    table.insert(new_file, target_start + idx, line)
  end

  local original_text = table.concat(original_file, "\n")
  local new_text = table.concat(new_file, "\n")
  local diff_body = vim.diff(original_text, new_text, {
    result_type = "unified",
    algorithm = "histogram",
    ctxlen = 3,
  }) or ""

  local header_path = vim.fn.fnamemodify(filepath, ":.")
  if not header_path or header_path == "" then
    header_path = filepath
  end
  if header_path:sub(1, 1) == "/" then
    header_path = header_path:sub(2)
  end

  local patch_lines = {
    "--- " .. header_path,
    "+++ " .. header_path,
  }
  if diff_body ~= "" then
    for line in diff_body:gmatch("[^\n]+") do
      table.insert(patch_lines, line)
    end
  else
    patch_lines[#patch_lines + 1] = "@@ identical @@"
  end

  local diff_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(diff_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(diff_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(diff_buf, "filetype", "diff")
  vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, patch_lines)

  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  local diff_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(diff_win, diff_buf)
  vim.api.nvim_set_current_win(current_win)

  local patchfile = vim.fn.tempname() .. ".patch"
  vim.fn.writefile(patch_lines, patchfile)
  common.store_last_refactor_patch({
    patchfile = patchfile,
    filepath = filepath,
    root_dir = vim.fn.getcwd(),
    diff_buf = diff_buf,
    diff_win = diff_win,
    patch_lines = patch_lines,
  })

  print(string.format("AIRefactor patch written to %s; diff opened in new split.", patchfile))
end, {
  -- allow zero or more instruction arguments
  nargs = "*",
  range = "%",
})

vim.api.nvim_create_user_command("AIRefactorApply", function()
  local last_refactor_patch = common.last_refactor_patch
  if not last_refactor_patch or not last_refactor_patch.patchfile then
    print("No AIRefactor patch available. Run :AIRefactor first.")
    return
  end

  local patchfile = last_refactor_patch.patchfile
  local filepath = last_refactor_patch.filepath
  if vim.fn.filereadable(patchfile) ~= 1 then
    print("AIRefactor patch file missing. Please rerun :AIRefactor.")
    return
  end

  local ok, output = common.apply_patchfile(patchfile, last_refactor_patch.root_dir)
  if not ok then
    print("Failed to apply patch: " .. output)
    return
  end

  common.close_last_refactor_diff()

  print("Patch applied. Reloading buffer...")
  vim.cmd("checktime")
end, {
  nargs = 0,
  range = "%",
})

vim.api.nvim_create_user_command("AIRefactorApplyHunks", function(opts)
  local last_refactor_patch = common.last_refactor_patch
  if not last_refactor_patch or not last_refactor_patch.patch_lines then
    print("No AIRefactor patch available. Run :AIRefactor first.")
    return
  end

  local hunks = common.parse_hunks(last_refactor_patch.patch_lines)
  if #hunks == 0 then
    print("No hunks to apply.")
    return
  end

  local selection = common.get_selection()
  if not selection and opts.range and opts.range > 0 then
    selection = {
      start_line = opts.line1,
      end_line = opts.line2,
    }
  end
  local selected_hunks = hunks
  if selection then
    local sel_start = selection.start_line
    local sel_end = selection.end_line
    selected_hunks = {}
    for _, hunk in ipairs(hunks) do
      local hunk_old_start = hunk.old_start
      local hunk_old_end = hunk.old_start + math.max(hunk.old_count - 1, 0)
      if not (sel_end < hunk_old_start or sel_start > hunk_old_end) then
        table.insert(selected_hunks, hunk)
      end
    end
    if #selected_hunks == 0 then
      print(string.format("No hunks overlap selection (%d-%d). Showing all hunks.", sel_start, sel_end))
      selected_hunks = hunks
    end
  end

  local function apply_hunk(hunk)
    local patch_lines = {
      last_refactor_patch.patch_lines[1],
      last_refactor_patch.patch_lines[2],
      hunk.header,
    }
    for _, line in ipairs(hunk.lines) do
      patch_lines[#patch_lines + 1] = line
    end

    local patchfile = vim.fn.tempname() .. ".hunk.patch"
    vim.fn.writefile(patch_lines, patchfile)

    local ok, output = common.apply_patchfile(patchfile, last_refactor_patch.root_dir)
    if not ok then
      print("Failed to apply hunk: " .. output)
      return false
    end
    return true
  end

  local function close_diff()
    common.close_last_refactor_diff()
  end

  local function select_next()
    local choices = {}
    for idx, hunk in ipairs(selected_hunks) do
      choices[idx] = string.format(
        "Hunk %d: -%d,%d +%d,%d",
        idx, hunk.old_start, hunk.old_count, hunk.new_start, hunk.new_count
      )
    end
    choices[#choices + 1] = "[Done] keep diff"
    choices[#choices + 1] = "[Done] close diff"

    vim.ui.select(choices, { prompt = "Select hunk to apply (Esc to stop)" }, function(choice, choice_idx)
      if not choice or not choice_idx then
        print("Stopped applying hunks. Diff remains open; rerun :AIRefactorApplyHunks to continue.")
        return
      end

      local done_keep = choice == "[Done] keep diff"
      local done_close = choice == "[Done] close diff"
      if done_keep or done_close then
        if done_close then
          close_diff()
        end
        return
      end

      local hunk = table.remove(selected_hunks, choice_idx)
      if not hunk then
        print("Invalid hunk selection.")
        return
      end

      local ok = apply_hunk(hunk)
      if not ok then
        return
      end

      print(string.format("Applied %s", choice))
      vim.cmd("checktime")

      if #selected_hunks == 0 then
        print("Selected hunks applied. Diff remains open; rerun :AIRefactorApplyHunks for other hunks.")
        return
      end

      select_next()
    end)
  end

  select_next()
end, {
  nargs = 0,
  range = "%",
})

vim.api.nvim_create_user_command("AIRefactorEditPatch", function()
  local state = common.last_refactor_patch
  if not state or not state.patch_lines then
    print("No AIRefactor patch available. Run :AIRefactor first.")
    return
  end

  local patchfile = state.patchfile
  if not patchfile or patchfile == "" or vim.fn.filereadable(patchfile) ~= 1 then
    patchfile = vim.fn.tempname() .. ".patch"
    vim.fn.writefile(state.patch_lines, patchfile)
    state.patchfile = patchfile
    common.store_last_refactor_patch(state)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(patchfile))
  vim.bo.filetype = "diff"
  print("Opened patch for editing: " .. patchfile)
end, {
  nargs = 0,
})
