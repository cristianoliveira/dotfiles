require("mason").setup()

local lspconfig = require('lspconfig')
local mason_lspconfig = require("mason-lspconfig")
local capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local util = require("lspconfig.util")
local configs = require("lspconfig.configs")

configs.htmx_lsp = {
  default_config = {
    -- Paste here the path to the lsp bin
    cmd = {
      "/Users/cristianoliveira/other/htmx-lsp/target/debug/htmx-lsp",
      "--file",
      "/Users/cristianoliveira/other/htmx-lsp/log.log",
      "--level",
      "DEBUG",
    },
    filetypes = { "html" },
    root_dir = util.path.dirname,
    autostart = true,
  },

  docs = {
    description = [[
    Language Server Protocol for Conventional Commits.
    ]],
    default_config = {
      root_dir = [[root_pattern(".git")]],
    },
  },
}

lspconfig.htmx_lsp.setup {
  on_attach = Lsp_on_attach, -- see ../mappings/lsp.lua
  flags = lsp_flags,
}


local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

local servers = {
  dockerls = {},

  gopls = {},
  rust_analyzer = {},
  tsserver = {},

  bashls = {},

  pyright = {},

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      diagnostics = {
        globals = { 'vim', 'describe', 'it', 'before_each', 'after_each', 'spy', 'use' },
      }
    },
  },
}

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers)
}


mason_lspconfig.setup_handlers {
  function(server_name)
    lspconfig[server_name].setup {
      capabilities = capabilities,
      on_attach = Lsp_on_attach, -- see ../mappings/lsp.lua
      settings = servers[server_name],
      flags = lsp_flags,
    }
  end,
}
