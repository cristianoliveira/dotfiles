local opts = { noremap = true, silent = true }

-- diagnostic mapping
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>dj', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>dk', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', '<leader>de', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, opts)

-- Go to definition and center screen
nmap("<C-]>", "<C-]>zz")

-- Use a on_attach function to only map the following keys
-- after the language server attaches to the current buffer
Lsp_on_attach = function(_, bufnr)
  local lspnmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { noremap = true, silent = true, buffer = bufnr, desc = desc })
  end

  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  lspnmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  lspnmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
  lspnmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
  lspnmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  lspnmap('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
  lspnmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
  lspnmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

  lspnmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
  lspnmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd')
  lspnmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove')
  lspnmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, "[W]orkspace [L]ist")

  -- See `:help K` for why this keymap
  lspnmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  lspnmap('<C-K>', vim.lsp.buf.signature_help, 'Signature Documentation')
end
