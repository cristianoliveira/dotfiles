--- Open current selected line in vscode using g
--- code --goto <file>:<line>
vim.api.nvim_create_user_command("VSCode", function(opts)
  local file = vim.fn.expand("%")
  local line = vim.fn.line(".")
  local cmd = ":!code --goto " .. file .. ":" .. line
  vim.cmd(cmd)
end, { nargs = 0 })
