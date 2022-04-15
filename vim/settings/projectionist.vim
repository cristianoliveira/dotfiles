let g:projectionist_heuristics = {
      \ "package.json": {
        \    "*.js": {
        \      "alternate": "{}.spec.js"
        \    },
        \    "*.spec.js": {
        \      "alternate": "{}.js"
        \    }
        \  }
      \}
