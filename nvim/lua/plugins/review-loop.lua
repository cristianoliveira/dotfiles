-- Persistent incremental diff reviewer (local dev plugin).
-- :ReviewLoop opens a sidebar + two-pane diff with inline review comments;
-- <leader>rs submits, checkpointing the workspace and composing feedback.
--
-- The checkout lives outside the dotfiles, so load it live with dev = true and
-- only when present -- keeps this config portable across machines.
local dir = vim.fn.expand "~/other/pi-review-loop/nvim"

return {
  "earendil-works/pi-review-loop",
  dir = dir,
  dev = true,
  cond = function()
    return vim.loop.fs_stat(dir) ~= nil
  end,
  main = "review-loop",
  opts = {},
  cmd = "ReviewLoop",
  keys = {
    { "<leader>dr", "<cmd>ReviewLoop<cr>", desc = "[D]iff [R]eview loop" },
  },
  dependencies = { "nvim-lua/plenary.nvim" }, -- powers the test suite
}
