-- [[ Vim Projectionist setting ]]
--
-- This configuration allows one to quick create/jump to related files
-- Common usage is use :A to alternate between the files in the pattern
-- Eg. `Foo.ts` (:A) -> `Foo.spec.ts` (:A) -> `Foo.ts`
--
-- It also allows to jump to a specific "type" of related file by :E<type>
-- Eg. `Foo.tsx` (:Estyle) -> `Foo.module.css`
--
-- See :help projectionist
vim.g.projectionist_heuristics = {
  -- [[ Typescript and javascript euristics for projectionist ]]
  ['package.json'] = {
    ['*.js'] = {
      ['alternate'] = { '{}.spec.js', '{}.test.js' },
      ['type'] = "test"
    },
    ['*.test.js'] = {
      ['alternate'] = { '{}.js' },
    },
    ['*.spec.js'] = {
      ['alternate'] = { '{}.js' },
    },
    ['*.ts'] = {
      ['alternate'] = { '{}.spec.ts', '{}.test.ts' },
      ['type'] = "test"
    },
    ['*.spec.ts'] = {
      ['alternate'] = { '{}.ts' },
      -- Run linter 
    },
    ['*.test.ts'] = {
      ['alternate'] = { '{}.ts' },
      ['dispatch'] = { 'npm run test -- --watch' },
    },

    -- React specific --
    ['*.tsx'] = {
      ['alternate'] = { '{}.spec.tsx', '{}.test.tsx' },
      -- Allow :Etest to jump to alternative file eg from `Foo.tsx` to `Foo.spec.tsx`
      ['type'] = "test"
    },
    ['*.module.css'] = {
      ['alternate'] = { '{}.tsx' },
      -- Allow :Estyle to jump to alternative file eg from `Foo.tsx` to `Foo.module.css`
      ['type'] = "style"
    },
    ['*.spec.tsx'] = {
      ['alternate'] = { '{}.tsx' },
    },
    ['*.test.tsx'] = {
      ['alternate'] = { '{}.tsx' },
    },
    ['*.jsx'] = {
      ['alternate'] = { '{}.spec.jsx' },
      ['type'] = "test"
    },
    ['*.spec.jsx'] = {
      ['alternate'] = { '{}.jsx' }
    },
    -- redux pattern
    ['*/reducer.ts'] = {
      ['alternate'] = { '{}/actions.ts', '{}/types.ts', '{}/state.ts', '{}/selectors.ts' },
      ['type'] = "redux"
    },
    ['*/actions.ts'] = {
      ['alternate'] = { '{}/reducer.ts', '{}/types.ts', '{}/state.ts', '{}/selectors.ts' },
      ['type'] = "redux"
    },
    ['*/types.ts'] = {
      ['alternate'] = { '{}/reducer.ts', '{}/actions.ts', '{}/state.ts', '{}/selectors.ts' },
      ['type'] = "redux"
    },
    ['*/state.ts'] = {
      ['alternate'] = { '{}/reducer.ts', '{}/actions.ts', '{}/types.ts', '{}/selectors.ts' },
      ['type'] = "redux"
    },
    ['*/selectors.ts'] = {
      ['alternate'] = { '{}/reducer.ts', '{}/actions.ts', '{}/types.ts', '{}/state.ts' },
      ['type'] = "redux"
    },
  },

  -- [[ Golang euristics for projectionist ]]
  ['go.mod'] = {
    ['*.go'] = {
      ['alternate'] = { '{}_test.go' }
    },
    ['*_test.go'] = {
      ['alternate'] = { '{}.go' }
    }
  },

  -- [[ Lua euristics for projectionist ]]
  ['init.lua'] = {
    ['*.lua'] = {
      ['alternate'] = { '{}_spec.lua' }
    },
    ['*_spec.lua'] = {
      ['alternate'] = { '{}.lua' }
    }
  },

  -- [[ Nix euristics for projectionist ]]
  ['*.nix'] = {
    ['flake.nix'] = {
      ['alternate'] = { 'flake.nix', 'shell.nix', 'default.nix' },
      ['type'] = "lock"
    },
    ['flake.lock'] = {
      ['alternate'] = { 'flake.nix' },
      ['type'] = "flake"
    },
    ['shell.nix'] = {
      ['alternate'] = { 'flake.nix' },
      ['type'] = "shell"
    },
    ['default.nix'] = {
      ['alternate'] = { 'flake.nix' },
      ['type'] = "default"
    },
    ['packages.nix'] = {
      ['alternate'] = { 'flake.nix' },
      ['type'] = "pkgs"
    },
  },
  -- [[ Funzzy euristics for projectionist ]]
  ['.watch.yaml'] = {
    ['.watch.yaml'] = {
      ['alternate'] = { '.watch.yaml' },
      ['type'] = "Watch"
    },
  },

  ['.scripts/'] = {
    ['.scripts/*.sh'] = {
      ['alternate'] = { '.scripts/*.sh' },
      ['type'] = "Do"
    },
  },

  ['.tmp/notes'] = {
    ['.tmp/notes/*'] = {
      ['type'] = "TNotes"
    },
  },

  -- [[ Dotenv (with example) euristics for projectionist ]]
  ['.env-example'] = {
    ['.env'] = {
      ['alternate'] = { '.env-example', '.env', '.env.local' },
      ['type'] = "EnvExample"
    }
  },

  -- [[ Github actions euristics for projectionist ]]
  -- USAGE: :ECI <workflow> to jump to the CI workflow (use TAB to autocomplete)
  ['.github/workflows/'] = {
    ['.github/workflows/*.yml'] = {
      ['alternate'] = { '.github/workflows/*.yml' },
      ['type'] = "CI"
    },
  },


  -- [[ Git hooks euristic for Projectionist ]]
  -- USAGE: EGHooks <hook> to jump to the hook file
  ['.git/hooks/'] = {
    ['.git/hooks/*'] = {
      ['alternate'] = { '.git/hooks/*' },
      ['type'] = "GHook"
    },
  },
}
