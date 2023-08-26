function fd_to_quickfix(args)
  local current_pwd = vim.fn.getcwd()
  local handle = io.popen("fd " .. args .. " " .. current_pwd .. " -t d")
  if handle == nil then
    print("fd cli is not found. Install it first.")
    return
  end

  local result = handle:read("*a")
  handle:close()

  local lines = {}
  for s in result:gmatch("[^\r\n]+") do
    table.insert(lines, { filename = s })
  end

  vim.fn.setqflist({}, ' ', { title = 'Directories found', items = lines })
  vim.cmd('copen')
end

vim.cmd("command! -nargs=1 Fd lua fd_to_quickfix(<f-args>)")
