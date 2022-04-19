let g:projectionist_heuristics = {
      \ "package.json": {
        \    "*.js": {
        \      "alternate": "{}.spec.js"
        \    },
        \    "*.spec.js": {
        \      "alternate": "{}.js"
        \    },
        \    "*.ts": {
        \      "alternate": "{}.spec.ts"
        \    },
        \    "*.spec.ts": {
        \      "alternate": "{}.ts"
        \    }
        \  }
      \}
