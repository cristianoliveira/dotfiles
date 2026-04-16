--- Git/Fugitive custom commands

--- :GFilesDiff [RANGE]
--- Examples:
---   :GFilesDiff        -> HEAD~1..HEAD
---   :GFilesDiff -2     -> HEAD~2..HEAD
---   :GFilesDiff HEAD~3..HEAD~1
vim.api.nvim_create_user_command("GFilesDiff", function(opts)
  local arg = (opts.args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local range = "HEAD~1..HEAD"

  if arg ~= "" then
    if arg:match("^%-%d+$") then
      local count = tonumber(arg:sub(2))
      if count and count > 0 then
        range = string.format("HEAD~%d..HEAD", count)
      end
    elseif arg:find("%.%.") then
      range = arg
    else
      range = string.format("%s..HEAD", arg)
    end
  end

  local cmd = { "git", "diff", "--name-only", range }
  local files = vim.fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify(string.format("GFilesDiff failed for range: %s", range), vim.log.levels.ERROR)
    return
  end

  local qf_items = {}
  for _, file in ipairs(files) do
    if file ~= "" then
      table.insert(qf_items, {
        filename = file,
        lnum = 1,
        col = 1,
        text = string.format("changed in %s", range),
      })
    end
  end

  vim.fn.setqflist({}, "r", {
    title = string.format("GFilesDiff %s", range),
    items = qf_items,
  })

  if #qf_items == 0 then
    vim.notify(string.format("No changed files for range: %s", range), vim.log.levels.INFO)
    vim.cmd("cclose")
    return
  end

  vim.cmd("copen")
end, {
  nargs = "?",
  desc = "Populate quickfix with files changed in git diff range (supports -N => HEAD~N..HEAD)",
})
