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

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  lspnmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  lspnmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
  lspnmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
  lspnmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  lspnmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
  lspnmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
  lspnmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  lspnmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  lspnmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  lspnmap('<C-K>', vim.lsp.buf.signature_help, 'Signature Documentation')

  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<leader>sgh', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<leader>ff', function() vim.lsp.buf.format { async = true } end, bufopts)

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end
