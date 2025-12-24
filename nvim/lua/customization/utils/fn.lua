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
  for idx, item in ipairs(list) do
    table.insert(result, fn(item, idx))
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
  for idx, item in ipairs(list) do
    if fn(item) then
      table.insert(result, item, idx)
    end
  end
  return result
end

--- Reduce function
--- Receives a table list and applies the function to accumulate a result
---
--- @param list table -- The list to be reduced
--- @param fn function -- The reducer function (accumulator, current_value, index)
--- @param initial any -- The initial value for the accumulator
---
--- @return any
function M.reduce(list, fn, initial)
  local accumulator = initial
  for idx, item in ipairs(list) do
    accumulator = fn(accumulator, item, idx)
  end
  return accumulator
end

--- For each function
--- Applies a function to each element of a list without returning a new list
---
--- @param list table -- The list to iterate over
--- @param fn function -- The function to apply to each element (receives item, index)
---
--- @return nil
function M.for_each(list, fn)
  for idx, item in ipairs(list) do
    fn(item, idx)
  end
end

return M
