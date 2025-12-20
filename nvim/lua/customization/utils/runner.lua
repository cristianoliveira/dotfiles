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

return M
