vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set timeoutlen for commands
vim.opt.timeoutlen = 1300

-- Set vim backup off
vim.opt.backup = false
vim.opt.backupcopy = 'no'
vim.opt.backupdir = "~/vimtmp//,."
vim.opt.directory = "~/vimtmp//,."
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Set highlight on search
vim.opt.hlsearch = true

-- Enable mouse mode
vim.opt.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true

-- Make left column at smalest size
vim.wo.signcolumn = 'yes:1'
vim.wo.foldcolumn = '0'
vim.wo.numberwidth = 1

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.opt.termguicolors = true

vim.opt.colorcolumn = "80"

-- Terminal colors and encoding
vim.opt.termguicolors = true
vim.opt.encoding = "utf-8"
vim.opt.fileencodings = { "utf-8" }
vim.opt.background = "dark"

-- Indentation
vim.opt.autoindent = true
vim.opt.cindent = true
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftround = true

vim.opt.wildignore = { 
  "*/.git/*",
  "*/tmp/*",
  "*.swp", 
  "*.pyc",
  "*/node_modules/*"
}

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

-- History and undo
vim.opt.undofile = true
vim.opt.history = 1000
vim.opt.undolevels = 1000

-- Syntax
vim.opt.synmaxcol = 512

vim.cmd [[syntax on]]
vim.cmd [[syntax sync minlines=256]]

vim.opt.cursorline = true
vim.opt.linespace = 3

-- Tab is 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

--> Navigation settings
vim.opt.relativenumber = true
vim.g.netrw_liststyle = 0

-- Make line numbers default
vim.wo.number = true

--> Performance settings
vim.opt.ttyfast = true
vim.opt.lazyredraw = true

-- Performance fix for Typescript
-- https://jameschambers.co.uk/vim-typescript-slow
-- Avoid using old regex implementation for code highlight which is slooow
vim.opt.re = 0

-- Working on a monorepop is fun!
-- See: https://github.com/vim/vim/issues/2049
vim.opt.mmp = 5000

-- Enable transparent background on startup
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    vim.cmd [[highlight Normal guibg=none
    highlight NonText guibg=none
    highlight Normal ctermbg=none
    highlight NonText ctermbg=none]]
  end,
  pattern = '*',
})
