-- Ensure files with .curl extension are treated as shell scripts
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = "*.curl",
  callback = function()
    vim.bo.filetype = "bash"
  end,
})
