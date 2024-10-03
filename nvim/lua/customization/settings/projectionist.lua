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
    },
    ['*.test.ts'] = {
      ['alternate'] = { '{}.ts' },
    },
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
    }
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
      ['alternate'] = { 'flake.lock', 'shell.nix', 'default.nix' },
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
  }
}
