-- If the plugin is in the file system attempt to load it
-- Otherwise, use lazy loading
if vim.fn.isdirectory(vim.fn.expand('~/other/dogmeat.nvim')) then
  print('[INF0] Loading dogmeat.nvim plugin')
  return {
    dir = vim.fn.expand('~/other/dogmeat.nvim'),
    config = function()
      require('dogmeat.nvim_commands').setup()
    end,
  }
end

return {}
