require("mason").setup()

local lspconfig = require('lspconfig')
local lsputils = require("lspconfig.util")
local mason_lspconfig = require("mason-lspconfig")
local capabilities = require('cmp_nvim_lsp')
  .default_capabilities(vim.lsp.protocol.make_client_capabilities())

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

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

  golangci_lint_ls = {},
}

mason_lspconfig.setup {
  automatic_enable = false,
  automatic_installation = true,
  ensure_installed = vim.tbl_keys(servers)
}

-- NOTE: Nixd requires to be installed with nix
-- see also "../../../../nix/shared/developer-tools.nix"
vim.lsp.config("nixd",  {
  cmd = { "/run/current-system/sw/bin/nixd" },
  capabilities = capabilities,
  on_attach = Lsp_on_attach, -- see ../mappings/lsp.lua
  settings = {},
  flags = lsp_flags,
})

vim.lsp.config("golangci_lint_ls",  {
  root_dir = lsputils.root_pattern("go.work", "go.mod", ".git"),
  cmd = { "golangci-lint-langserver" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  init_options = {
    command = { 'golangci-lint', 'run', '--output.json.path=stdout', '--show-stats=false' },
  },
  capabilities = capabilities,
  on_attach = Lsp_on_attach,
  settings = {},
  flags = lsp_flags,
})
