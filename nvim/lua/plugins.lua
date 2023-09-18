-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  ----------------------------------------------------------------------------
  -- Git related plugins

  'tpope/vim-fugitive',
  'ruanyl/vim-gh-line',

  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>gp', require('gitsigns').prev_hunk,
          { buffer = bufnr, desc = '[G]o to [P]revious Hunk' })
        vim.keymap.set('n', '<leader>gn', require('gitsigns').next_hunk, { buffer = bufnr, desc = '[G]o to [N]ext Hunk' })
        vim.keymap.set('n', '<leader>ph', require('gitsigns').preview_hunk, { buffer = bufnr, desc = '[P]review [H]unk' })
      end,
    },
  },

  ----------------------------------------------------------------------------
  -- Vim motions enhance plugins and code editing

  'tpope/vim-surround',

  -- Multiple cursors with Ctrl-n
  'mg979/vim-visual-multi',

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim',                    opts = {} },


  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },


  ----------------------------------------------------------------------------
  -- Vim project navigation

  -- Fuzzy Finder (files, lsp, etc)
  'tpope/vim-projectionist',
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },

  ----------------------------------------------------------------------------
  -- Auto completion and intellisense

  {
    'sirver/UltiSnips',
    config = function()
      vim.g.UltiSnipsExpandTrigger = "<C-l>"
      vim.g.UltiSnipsJumpForwardTrigger = "<C-l>"
    end,
    build = 'python3 -m pip install --user --upgrade pynvim',
    dependencies = {
      'honza/vim-snippets',
    },
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            accept = "<Tab>",
            next = "<C-h>",
          },
        },
      })
    end,
  },

  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim',       tag = 'legacy', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      'quangnguyen30192/cmp-nvim-ultisnips',
    },

    config = function()
      -- optional call to setup (see customization section)
      require("cmp_nvim_ultisnips").setup {}
    end,
  },

  -- Useful plugin to show you pending keybinds.
  {
    'folke/which-key.nvim',
    opts = {},
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 1000
    end,
  },

  {
    'cristianoliveira/snipgpt.nvim',
    build = 'npm i snipgpt -g',
  },

  ----------------------------------------------------------------------------
  -- Vim visual enhancements

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',
  'bling/vim-airline',

  {
    'maxmx03/solarized.nvim',
    lazy = false,
    priority = 1000,
    enables = {
      editor = true,
      syntax = true,
    },
    config = function()
      vim.o.background = 'dark' -- or 'light'

      vim.cmd.colorscheme 'solarized'
    end,
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    opts = {
      char = '┊',
      show_trailing_blankline_indent = false,
    },
  },


  ----------------------------------------------------------------------------
  -- Code runners and watchers

  {
    'cristianoliveira/funzzy.nvim',
    build = 'cargo install funzzy'
  },


}, {})

require('solarized').setup({ theme = 'neo' })

-- Setup neovim lua configuration
require('neodev').setup()
