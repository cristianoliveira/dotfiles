-- Use argslist to mimic harpoon functionality
--
local M = {}

M.add_file = function()
  local current_file = vim.fn.expand("%:p")
  vim.cmd("argadd %")
  vim.cmd("argdedup")
  print("Added to argslist: " .. current_file)
end

M.add_file_to_index = function(index)
  local current_file = vim.fn.expand("%:p")
  vim.cmd(index .. "argadd %")
  vim.cmd("argdedup")
  print("Added to argslist at index " .. index .. ": " .. current_file)
end

M.show_files = function()
  local argslist = vim.fn.argv()
  if #argslist == 0 then
    print("Argslist is empty.")
    return
  end

  print("Files in argslist:")
  for i, file in argslist do
    print(i .. ": " .. file)
  end
end

M.get_files = function()
  return vim.fn.argv()
end

M.goto_file = function(index)
  local argslist = vim.fn.argv()
  if index < 1 or index > #argslist then
    print("Index out of bounds.")
    return
  end

  vim.cmd("silent! ".. index .. "argument")
  print("Switched to file: " .. argslist[index])
end

M.delete_file = function(index)
  local argslist = vim.fn.argv()
  if index < 1 or index > #argslist then
    print("Index out of bounds.")
    return
  end

  vim.cmd("silent! " .. index .. "argdelete")
  print("Deleted file at index: " .. index)
end

vim.cmd("command! ArgAdd lua require('customization.plugins.argpoon').add_file()")
vim.cmd("command! -nargs=1 ArgAddAt lua require('customization.plugins.argpoon').add_file_to_index(<f-args>)")
vim.cmd("command! ArgShow lua require('customization.plugins.argpoon').show_files()")
-- Goto with args
vim.cmd("command! -nargs=1 ArgGoto lua require('customization.plugins.argpoon').goto_file(tonumber(<f-args>))")
vim.cmd("command! -nargs=1 ArgDel lua require('customization.plugins.argpoon').delete_file(tonumber(<f-args>))")

return M
