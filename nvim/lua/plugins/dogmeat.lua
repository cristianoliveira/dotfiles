-- If the plugin is in the file system attempt to load it
-- Otherwise, use lazy loading
if vim.fn.isdirectory(vim.fn.expand('~/other/nvim.dogmeat.')) then
  return {
    dir = vim.fn.expand('~/other/nvim.dogmeat'),
    config = function()
      require('dogmeat.nvim_commands').setup()
    end,
  }
end

return nil
