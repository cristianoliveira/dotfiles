require("mason").setup()

local lspconfig = require('lspconfig')
local mason_lspconfig = require("mason-lspconfig")
local capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

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
