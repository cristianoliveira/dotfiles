local root = vim.fn.getcwd()
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local open_file = require("customization.open_file")
local test_home = vim.fn.tempname()
local target = test_home .. "/example.txt"

vim.fn.mkdir(test_home, "p")
vim.fn.writefile({ "example" }, target)
vim.env.GF_TEST_HOME = test_home

vim.cmd.enew()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "$GF_TEST_HOME/example.txt" })
vim.api.nvim_win_set_cursor(0, { 1, 1 })
open_file.under_cursor()

assert(vim.fn.expand("%:p") == target, "gf should expand environment variables before opening file")

vim.cmd.enew({ bang = true })
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "$GF_TEST_HOME/missing.txt" })
vim.api.nvim_win_set_cursor(0, { 1, 1 })

local opened_missing_file = pcall(open_file.under_cursor)
assert(not opened_missing_file, "gf should keep failing when target does not exist")

vim.fn.delete(test_home, "rf")
print("gf_spec: ok")
