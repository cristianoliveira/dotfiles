local completion_preview = require("supermaven-nvim.completion_preview")

vim.keymap.set(
  "i",
  "<Tab>",
  completion_preview.on_accept_suggestion,
  { noremap = true, silent = true }
)
