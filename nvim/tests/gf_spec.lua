local root = vim.fn.getcwd()
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local open_file = require("customization.open_file")
local test_home = vim.fn.tempname()
local target = test_home .. "/example.txt"
local current_dir = test_home .. "/project/deep"
local current_file = current_dir .. "/current.md"
local backward_target = test_home .. "/back/file.txt"
local forward_target = current_dir .. "/my/forward/file.txt"

local function assert_current_file(expected, message)
  assert(vim.fn.resolve(vim.fn.expand("%:p")) == vim.fn.resolve(expected), message)
end

vim.fn.mkdir(current_dir, "p")
vim.fn.mkdir(test_home .. "/back", "p")
vim.fn.mkdir(current_dir .. "/my/forward", "p")
vim.fn.writefile({ "example" }, target)
vim.fn.writefile({ "backward" }, backward_target)
vim.fn.writefile({ "forward" }, forward_target)
vim.env.GF_TEST_HOME = test_home

vim.cmd.enew()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "$GF_TEST_HOME/example.txt" })
vim.api.nvim_win_set_cursor(0, { 1, 1 })
open_file.under_cursor()

assert_current_file(target, "gf should expand environment variables before opening file")

vim.fn.writefile({ "../../back/file.txt" }, current_file)
vim.cmd.edit(vim.fn.fnameescape(current_file))
vim.api.nvim_win_set_cursor(0, { 1, 1 })
open_file.under_cursor()

assert_current_file(backward_target, "gf should resolve backward paths from the current file")

vim.fn.writefile({ "my/forward/file.txt" }, current_file)
vim.cmd.edit(vim.fn.fnameescape(current_file))
vim.api.nvim_win_set_cursor(0, { 1, 1 })
open_file.under_cursor()

assert_current_file(forward_target, "gf should resolve forward paths from the current file")

vim.cmd.enew({ bang = true })
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "$GF_TEST_HOME/missing.txt" })
vim.api.nvim_win_set_cursor(0, { 1, 1 })

local opened_missing_file = pcall(open_file.under_cursor)
assert(not opened_missing_file, "gf should keep failing when target does not exist")

vim.fn.delete(test_home, "rf")
print("gf_spec: ok")
