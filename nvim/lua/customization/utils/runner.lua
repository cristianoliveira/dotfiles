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

return M
