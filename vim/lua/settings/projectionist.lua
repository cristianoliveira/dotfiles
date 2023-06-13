vim.g.projectionist_heuristics = {
  ['package.json'] = {
    ['*.js'] = {
      ['alternate'] = { '{}.spec.js' }
    },
    ['*.spec.js'] = {
      ['alternate'] = { '{}.js' }
    },
    ['*.ts'] = {
      ['alternate'] = { '{}.spec.ts' }
    },
    ['*.spec.ts'] = {
      ['alternate'] = { '{}.ts' }
    },
    ['*.tsx'] = {
      ['alternate'] = { '{}.spec.tsx' }
    },
    ['*.spec.tsx'] = {
      ['alternate'] = { '{}.tsx' }
    },
    ['*.jsx'] = {
      ['alternate'] = { '{}.spec.jsx' }
    },
    ['*.spec.jsx'] = {
      ['alternate'] = { '{}.jsx' }
    }
  },

  ['go.mod'] = {
    ['*.go'] = {
      ['alternate'] = { '{}_test.go' }
    },
    ['*_test.go'] = {
      ['alternate'] = { '{}.go' }
    }
  },

  ['init.lua'] = {
    ['*.lua'] = {
      ['alternate'] = { '{}_spec.lua' }
    },
    ['*_spec.lua'] = {
      ['alternate'] = { '{}.lua' }
    }
  }
}
