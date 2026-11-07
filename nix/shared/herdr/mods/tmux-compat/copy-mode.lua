-- Snapshot contents are untrusted data, never editor configuration or commands.
vim.opt.modeline = false
vim.opt.exrc = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.shada = ""
vim.opt.clipboard = ""
vim.opt.mouse = ""
vim.opt.number = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.laststatus = 2
local title = vim.env.HERDR_COPY_SCREEN_ONLY == "1" and "COPY MODE (screen only)" or "COPY MODE"
vim.opt.statusline = " " .. title .. " · hjkl move · / search · v/V/Ctrl-v select · y copy · q exit"

vim.keymap.set("n", "q", "<cmd>qa!<CR>")
vim.keymap.set("n", "<Esc>", "<cmd>qa!<CR>")
vim.keymap.set("n", "Q", "<Nop>")
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function() vim.cmd("normal! G0") end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator ~= "y" then return end
    local lines = vim.v.event.regcontents
    if #table.concat(lines, "\n") > 1024 * 1024 then
      vim.api.nvim_echo({ { "Selection exceeds Herdr's 1 MiB clipboard limit" } }, false, {})
      return
    end
    -- Herdr handles OSC 52 locally, including when the source terminal is remote.
    require("vim.ui.clipboard.osc52").copy("+")(lines)
    vim.api.nvim_echo({ { "Copied · q exits" } }, false, {})
  end,
})
