local M = {}

---Convert an iterator to a table
---@param iterator function An iterator function that returns values one at a time
---@return table A new table containing all elements from the iterator in order
---@example
--- local t = iterator_to_table(string.gmatch("a,b,c", "[^,]+")) -- Returns {"a", "b", "c"}
M.iterator_to_table = function(iterator)
  -- test if iterator is a function
  if type(iterator) ~= "function" then
    error("Expected a function as an iterator")
  end

  local result = {}
  for value in iterator() do
    table.insert(result, value)
  end
  return result
end

return M
