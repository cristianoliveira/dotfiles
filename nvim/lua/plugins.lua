-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
print('Checking if ' .. lazypath .. ' exists')
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
  'tpope/vim-rhubarb',
  -- 'ruanyl/vim-gh-line',

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
    -- NOTE: added via nix in 
    -- build = 'pip3 install --user --upgrade pynvim',
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
        filetypes = {
          markdown = true,
          yaml = true,
        },
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
      { 'mason-org/mason.nvim', config = true },
      'mason-org/mason-lspconfig.nvim',

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
    version = '2',
    opts = {
      char = '┊',
      show_trailing_blankline_indent = false,
    },
  },

  ----------------------------------------------------------------------------
  -- Code runners and watchers

  -- Fzz watcher to run commands in parallel
  -- (function()
  --   local funzzy_vim_plugin = {
  --     'cristianoliveira/funzzy.nvim',
  --     build = 'cargo install funzzy'
  --   };
  --
  --   -- Check if there is a local development version of funzzy
  --   -- in the `~/other/funzzy.nvim` directory then change the pl
  --   if vim.loop.fs_stat(vim.fn.expand('~/other/funzzy.nvim')) then
  --     funzzy_vim_plugin = {
  --       dir = "~/other/funzzy.nvim",
  --       config = function()
  --         vim.g.funzzy_bin = '~/.cargo/bin/fzz'
  --         vim.g.fzz_bin = '~/.cargo/bin/fzz'
  --       end,
  --     }
  --   end
  --
  --   return funzzy_vim_plugin
  -- end)(),

  -- Curl.nvim to run curl commands within neovim
  -- Select curl and execute with :CurlOpen
  {
    "oysandvik94/curl.nvim",
    cmd = { "CurlOpen" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = true,
  },

  ----------------------------------------------------------------------------
  -- Plugins to search on the web

  -- Search on github
  {
    'thenbe/csgithub.nvim',
    keys = {
      {
        '<leader>ghs',
        function()
          local csgithub = require('csgithub')
          local url = csgithub.search({
            includeFilename = false,
            includeExtension = true,
          })
          csgithub.open(url)
        end,
        mode = { 'v', 'n' },
        desc = 'Search Github (extension)',
      },
      {
        '<leader>rhsf',
        function()
          local csgithub = require('csgithub')
          local url = csgithub.search({
            includeFilename = true,
            includeExtension = true,
          })
          csgithub.open(url)
        end,
        mode = { 'v', 'n' },
        desc = 'Search Github (filename)',
      },
    },
  },

  ----------------------------------------------------------------------------
  --- Debugging plugins
  
  -- Golang dap integration
  {
    'leoluz/nvim-dap-go',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      require('dap-go').setup()
    end,
  },

}, {})

require('solarized').setup({ theme = 'neo' })

-- Setup neovim lua configuration
require('neodev').setup()
