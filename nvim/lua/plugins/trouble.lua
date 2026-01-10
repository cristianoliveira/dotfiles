-- Use `:Trouble diagnostics` to open the list of diagnostics
-- Use `:Trouble lsp` to open the list of diagnostics from the current buffer
-- Use `:Trouble quickfix` to open the list of quickfix items
-- For more `:help Trouble`
return {
  "folke/trouble.nvim",
  -- @type trouble.Config opts
  opts = {
    auto_close = true,
  },
  cmd = "Trouble",
}
