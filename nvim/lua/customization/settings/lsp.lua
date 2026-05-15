require("mason").setup()

local lsputils = require("lspconfig.util")
local mason_lspconfig = require("mason-lspconfig")
local capabilities = require('cmp_nvim_lsp')
    .default_capabilities(vim.lsp.protocol.make_client_capabilities())
local dotfiles_nix = vim.fn.expand("$HOME/.dotfiles/nix")

local servers = {
  dockerls = {},

  gopls = {},
  rust_analyzer = {},
  ts_ls = {},

  bashls = {},

  pyright = {},
  kotlin_language_server = (function()
    -- Prefer nix-provided binary (direnv/devShell).
    -- It inherits JAVA_HOME, Gradle, and proper environment from the nix shell.
    local nix_kls = vim.fn.executable("kotlin-language-server") == 1
        and vim.fn.exepath("kotlin-language-server")
        or nil
    local mason_kls = "/home/cristianoliveira/.local/share/nvim/mason/packages/kotlin-language-server/server/bin/kotlin-language-server"

    local cmd_path = nix_kls or mason_kls

    -- wire-cli is JVM-only; prevent the LSP from trying to configure Android
    -- modules in the Kalium composite build (avoids AGP/JDK compatibility issues).
    local cmd_env = {
      ORG_GRADLE_PROJECT_enableAndroid = "false",
    }
    -- When using the Mason-installed binary (no nix devShell active),
    -- inherit JAVA_HOME from the environment — the user is expected to
    -- have it set up (e.g. via their shell profile or another nix shell).
    if not nix_kls and os.getenv("JAVA_HOME") then
      cmd_env.JAVA_HOME = os.getenv("JAVA_HOME")
    end

    return {
      cmd = { cmd_path },
      cmd_env = cmd_env,
      settings = {
        kotlin = {
          compiler = {
            jvm = {
              target = "17",
            },
          },
          languageServer = {
            watchFiles = { "**/*.kt", "**/*.kts", "**/build.gradle.kts", "**/settings.gradle.kts" },
          },
          indexing = {
            enabled = true,
          },
          diagnostics = {
            enabled = true,
          },
          inlayHints = {
            typeHints = true,
            parameterHints = true,
          },
        },
      },
    }
  end)(),

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
    cmd = { vim.fn.exepath("nixd") ~= "" and vim.fn.exepath("nixd") or "nixd" },
    capabilities = capabilities,
    settings = {
      nixd = {
        nixpkgs = {
          expr = "import (builtins.getFlake \"" .. dotfiles_nix .. "\").inputs.nixpkgs { }",
        },
        options = {
          nixos = {
            expr = "(builtins.getFlake \"" .. dotfiles_nix .. "\").nixosConfigurations.nixos.options",
          },
          darwin = {
            expr = "(builtins.getFlake \"" .. dotfiles_nix .. "\").darwinConfigurations.darwin.options",
          },
        },
      },
    },
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
  vim.lsp.enable(name)
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
vim.lsp.enable('lua_ls')

mason_lspconfig.setup {
  ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
  automatic_installation = false,
}
