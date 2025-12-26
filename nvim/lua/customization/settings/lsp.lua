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

vim.lsp.config('lua_ls', {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath('config')
        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      -- diagnostics = {
      --   globals = {
      --     'vim',
      --     'describe',
      --     'it',
      --     'before_each',
      --     'after_each',
      --     'spy',
      --     'use'
      --   },
      -- },

      runtime = {
        -- Tell the language server which version of Lua you're using (most
        -- likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Tell the language server how to find Lua modules same way as Neovim
        -- (see `:h lua-module-load`)
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- Depending on the usage, you might want to add additional paths
          -- here.
          '${3rd}/luv/library',
          '${3rd}/busted/library',
        }
        -- Or pull in all of 'runtimepath'.
        -- NOTE: this is a lot slower and will cause issues when working on
        -- your own configuration.
        -- See https://github.com/neovim/nvim-lspconfig/issues/3189
        -- library = {
        --   vim.api.nvim_get_runtime_file('', true),
        -- }
      }
    })
  end,
  settings = {
    Lua = {}
  }
})

mason_lspconfig.setup {
  ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
  automatic_installation = false,
}
