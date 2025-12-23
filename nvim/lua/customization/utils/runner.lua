local M = {}

--- Command to run a command and return a table of lines
---
---@param command string The shell command to run
---@return table A table containing the lines of output from the command
M.execute = function(command)
  -- Execute command and collect the output
  local handle = io.popen(command, "r")
  if handle then
    local result = handle:read("*a")

    -- Split result into lines
    local lines = {}
    for line in result:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end


    handle:close()
    return lines
  end

  return {}
end

--- Command to run a command and stream lines to a callback while collecting them
---
---@param command string The shell command to run
---@param on_line fun(line: string)|nil Callback invoked for each line as it arrives
---@return table lines Collected lines from the command output
---@return string|nil err Error message if the callback fails
M.stream = function(command, on_line)
  local handle = io.popen(command, "r")
  if not handle then
    return {}, "failed to start command"
  end

  local lines = {}
  for line in handle:lines() do
    table.insert(lines, line)
    if on_line then
      local ok, err = pcall(on_line, line)
      if not ok then
        handle:close()
        return lines, err
      end
    end
  end

  handle:close()
  return lines, nil
end

--- Run a command asynchronously using Neovim jobs.
---
--- @class runner.AsyncOptions
--- @field on_success fun(code: integer, res: vim.SystemCompleted)|nil Callback invoked when the command completes successfully
--- @field on_error fun(stderr: string, res: vim.SystemCompleted)|nil Callback invoked when the command fails
---
---@param command string[] Shell command to run
---@param opts runner.AsyncOptions
---@return vim.SystemObj|nil processInf The spawned job id, or nil on failure
--
-- Example (collecting output and reacting to completion):
-- ```lua
-- M.async("ls -la", {
--   on_success = function(code, lines)
--     print("job finished with code", code)
--     print(table.concat(lines, "\n"))
--   end,
-- })
--
-- Example (stream stderr only, no collection):
-- M.async("make", {
--   collect_output = false,
--   on_success = function(_,lines)
--     vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
--   end,
-- })
-- ```
M.async = function(command, opts)
  opts = opts or {}
  local function safe_call(fn, ...)
    if not fn then
      return true
    end

    local ok, err = pcall(fn, ...)
    if not ok then
      vim.notify("runner.async callback error: " .. tostring(err), vim.log.levels.ERROR)
    end
    return ok
  end

  local processInf = vim.system(command, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        if opts.on_error then
          safe_call(opts.on_error, res.stderr or {}, res)
        end

        return
      end
      if opts.on_success then
        safe_call(opts.on_success, res.code, res)
      end
    end)
  end)

  if processInf.pid == nil then
    return nil
  end

  return processInf
end

return M
