require("mason").setup()

local lsputils = require("lspconfig.util")
local mason_lspconfig = require("mason-lspconfig")
local capabilities = require('cmp_nvim_lsp')
  .default_capabilities(vim.lsp.protocol.make_client_capabilities())

local servers = {
  dockerls = {},

  gopls = {},
  rust_analyzer = {},
  ts_ls = {},

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

  golangci_lint_ls = {
    root_dir = lsputils.root_pattern("go.work", "go.mod", ".git"),
    cmd = { "golangci-lint-langserver" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    init_options = {
      command = { 'golangci-lint', 'run', '--output.json.path=stdout', '--show-stats=false' },
    },
    capabilities = capabilities,
    settings = {},
  },

  -- NOTE: Nixd requires to be installed with nix
  -- see also "../../../../nix/shared/developer-tools.nix"
  nixd = {
    cmd = { "/run/current-system/sw/bin/nixd" },
    capabilities = capabilities,
    settings = {},
  },
}

-- Now setup those configurations
for name, cfg in pairs(servers) do
  local config = cfg or {}
  -- This handles overriding only values explicitly passed
  -- by the server configuration above. Useful when disabling
  -- certain features of an LSP (for example, turning off formatting for ts_ls)
  config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
  vim.lsp.config(name, config)
end

mason_lspconfig.setup {
  ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
  automatic_installation = false,
}
