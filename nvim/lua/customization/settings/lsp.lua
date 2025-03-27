require("mason").setup()

local lspconfig = require('lspconfig')
local mason_lspconfig = require("mason-lspconfig")
local capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local util = require("lspconfig.util")
local configs = require("lspconfig.configs")

-- Check if file "/Users/cristianoliveira/other/htmx-lsp/target/release/htmx-lsp" 
-- is present otherwise don't set up htmx_lsp
local htmx_lsp_bin = "/Users/cristianoliveira/other/htmx-lsp/target/release/htmx-lsp"
if vim.fn.filereadable(htmx_lsp_bin) ~= 0 then
  configs.htmx_lsp = {
    default_config = {
      -- Paste here the path to the lsp bin
      cmd = {
        "/Users/cristianoliveira/other/htmx-lsp/target/release/htmx-lsp",
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
end


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

-- NOTE: Nixd requires to be installed with nix
-- see also "../../../../nix/shared/developer-tools.nix"
lspconfig.nixd.setup {
  cmd = { "/run/current-system/sw/bin/nixd" },
  capabilities = capabilities,
  on_attach = Lsp_on_attach, -- see ../mappings/lsp.lua
  settings = {},
  flags = lsp_flags,
}
