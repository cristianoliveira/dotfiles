require("mason").setup()

local lsputils = require("lspconfig.util")
local mason_lspconfig = require("mason-lspconfig")
local capabilities = require('cmp_nvim_lsp')
    .default_capabilities(vim.lsp.protocol.make_client_capabilities())
local dotfiles_nix = vim.fn.expand("$HOME/.dotfiles/nix")

local function first_executable(candidates)
  for _, candidate in ipairs(candidates) do
    local executable = vim.fn.exepath(candidate)
    if executable ~= "" then
      return executable
    end

    local matches = vim.fn.glob(candidate, false, true)
    for _, match in ipairs(matches) do
      if vim.fn.executable(match) == 1 then
        return match
      end
    end
  end
end

local servers = {
  dockerls = {},

  gopls = {},
  rust_analyzer = {},
  ts_ls = {},

  bashls = {},

  pyright = {},
  kotlin_language_server = (function()
    -- wire-cli is JVM-only; prevent the LSP from trying to configure Android
    -- modules in the Kalium composite build (avoids AGP/JDK compatibility issues).
    local cmd_env = {
      ORG_GRADLE_PROJECT_enableAndroid = "false",
      JAVA_HOME = os.getenv("JAVA_HOME")
    }
    local kotlin_language_server = first_executable({
      "kotlin-language-server",
      "/nix/store/*-kotlin-language-server-*/bin/kotlin-language-server",
    })

    return {
      cmd = {
        "bash",
        "-lc",
        "exec \"$@\" 2> >(grep -v '^SLF4J:' >&2)",
        "kotlin-language-server-wrapper",
        kotlin_language_server or "kotlin-language-server",
      },
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
  automatic_enable = {
    exclude = { "kotlin_lsp" },
  },
}
