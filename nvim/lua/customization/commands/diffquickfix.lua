-- Navigate diffs via quickfix

--- DiffQuickfix command
--
-- Args:
--  file1: The first file to compare (optional if in diff mode)
--  file2: The second file to compare (optional if in diff mode)
--
-- Description:
-- Compares two files and populates the quickfix list with the differences.
-- Each diff hunk is added as a quickfix entry, allowing easy navigation
-- through the changes using :cnext and :cprev.
--
-- Usage:
--   :DiffQuickfix                       (when in diff mode, auto-detects files)
--   :DiffQuickfix path/to/file1 path/to/file2
--   :DiffQuickfix path/to/file          (compares with current buffer)
vim.api.nvim_create_user_command("DiffQuickfix", function(opts)
  local args = opts.fargs

  local file1, file2

  if #args == 0 then
    -- Try to detect files from diff mode
    local current_win = vim.api.nvim_get_current_win()
    local is_diff = vim.wo[current_win].diff

    if not is_diff then
      print("Not in diff mode. Usage: DiffQuickfix <file1> [file2]")
      return
    end

    -- Get all windows in the current tab that are in diff mode
    local diff_wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[win].diff then
        local buf = vim.api.nvim_win_get_buf(win)
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname ~= "" then
          table.insert(diff_wins, bufname)
        end
      end
    end

    if #diff_wins < 2 then
      print("Error: Need at least 2 files in diff mode")
      return
    end

    if #diff_wins > 2 then
      print("Warning: More than 2 files in diff mode, comparing first two")
    end

    file1 = diff_wins[1]
    file2 = diff_wins[2]
  elseif #args == 1 then
    file1 = args[1]
    local current_buf = vim.api.nvim_buf_get_name(0)
    if current_buf == "" then
      print("Current buffer has no file. Please provide two file paths.")
      return
    end
    file2 = current_buf
  else
    file1 = args[1]
    file2 = args[2]
  end

  -- Expand file paths
  file1 = vim.fn.expand(file1)
  file2 = vim.fn.expand(file2)

  -- Check if files exist
  if vim.fn.filereadable(file1) == 0 then
    print("Error: Cannot read file: " .. file1)
    return
  end
  if vim.fn.filereadable(file2) == 0 then
    print("Error: Cannot read file: " .. file2)
    return
  end

  -- Run diff command
  local diff_cmd = string.format("diff -u %s %s",
    vim.fn.shellescape(file1),
    vim.fn.shellescape(file2))

  local output = vim.fn.system(diff_cmd)

  -- Parse diff output and create quickfix entries
  local qf_list = {}
  local current_file = nil
  local current_line = nil

  for line in output:gmatch("[^\r\n]+") do
    -- Match hunk headers: @@ -l,s +l,s @@
    local new_line = line:match("^@@ %-(%d+)")
    if new_line then
      current_line = tonumber(new_line)
      current_file = file1

      -- Add the hunk header as a quickfix entry
      table.insert(qf_list, {
        filename = current_file,
        lnum = current_line,
        text = line,
        type = "I"
      })
    elseif line:match("^%+%+%+ (.+)") then
      -- Track the second file name
      local fname = line:match("^%+%+%+ (.+)")
      -- Remove the timestamp if present
      fname = fname:match("^([^\t]+)")
      if fname ~= "/dev/null" then
        current_file = fname
      end
    elseif line:match("^%-") and not line:match("^%-%-%-") then
      -- Line removed from file1
      if current_line and current_file then
        table.insert(qf_list, {
          filename = file1,
          lnum = current_line,
          text = "- " .. line:sub(2),
          type = "W"
        })
      end
    elseif line:match("^%+") and not line:match("^%+%+%+") then
      -- Line added to file2
      if current_line and current_file then
        table.insert(qf_list, {
          filename = file2,
          lnum = current_line,
          text = "+ " .. line:sub(2),
          type = "I"
        })
      end
    elseif current_line and line:match("^ ") then
      -- Context line - increment line counter
      current_line = current_line + 1
    end
  end

  if #qf_list == 0 then
    print("No differences found between the files")
    return
  end

  -- Set the quickfix list
  vim.fn.setqflist(qf_list, 'r')
  vim.fn.setqflist({}, 'a', {
    title = string.format("Diff: %s vs %s",
      vim.fn.fnamemodify(file1, ":t"),
      vim.fn.fnamemodify(file2, ":t"))
  })

  -- Open the quickfix window
  vim.cmd("copen")

  print(string.format("Found %d differences. Use :cnext/:cprev to navigate", #qf_list))
end, {
  nargs = "*",
  complete = "file"
})
