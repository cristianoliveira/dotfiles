local M = {}

--- Map function
--- Receives a table list and applies the function to each element
---
--- @param list table
--- @param fn function
---
--- @return table
function M.map(list, fn)
  local result = {}
  for _, item in ipairs(list) do
    table.insert(result, fn(item))
  end
  return result
end

--- Filter function
--- Receives a table list and applies the function to each element
---
--- @param list table -- The list to be filtered
--- @param fn function -- The condition function (must return true or false)
---
--- @return table
function M.filter(list, fn)
  local result = {}
  for _, item in ipairs(list) do
    if fn(item) then
      table.insert(result, item)
    end
  end
  return result
end

return M
