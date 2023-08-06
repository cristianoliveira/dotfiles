-- neovim create a function that get the test under the cursor
-- or the test under the visual selection and set .only to it
local M = {}

function M.get_test_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local test = string.match(line, "it('(.*)',")
  if test == nil then
    return
  end
  print('############# test', test)
  return test
end

function M.only_test()
  print('only_test aaaaaaaaaaaaaaaaaaaaaaaa')
  local test = M.get_test_under_cursor()
  print('test', test)
  if test == nil then
    return
  end
  -- vim replace "it" by "it.only"
  vim.api.nvim_command("normal! ^")
  vim.api.nvim_command("normal! cwit.only")
  vim.api.nvim_command("normal! $")
  vim.api.nvim_command("normal! i")
  vim.api.nvim_command("normal! " .. test)
  vim.api.nvim_command("normal! <esc>")
end

return M
