local M = {}

function M.under_cursor()
	local filename = vim.fn.expand("<cfile>")
	vim.cmd("find " .. vim.fn.fnameescape(filename))
end

return M
