vim.opt.timeoutlen = 1300

-- Working on a monorepop is fun!
-- See: https://github.com/vim/vim/issues/2049
vim.opt.mmp=5000

-- Set vim backup off
vim.opt.backup = false
vim.opt.backupcopy = 'no'
vim.opt.backupdir="~/vimtmp//,."
vim.opt.directory="~/vimtmp//,."
vim.opt.writebackup = false
