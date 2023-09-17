local cmp = require('cmp')

cmp.setup {
  preselect = cmp.PreselectMode.None,
  completion = {
    autocomplete = false
  },
  snippet = {
    expand = function(args)
      vim.fn["UltiSnips#Anon"](args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<tab>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'ultisnips' },
  },
  experimental = {
    ghost_text = false
  }
}

vim.keymap.set('i', '<C-k>', function()
  if cmp.visible() then
    cmp.select_prev_item()
  else
    cmp.complete();
  end
end, { noremap = true })

vim.keymap.set('i', '<C-j>', function()
  if cmp.visible() then
    cmp.select_next_item()
  else
    cmp.complete();
  end
end, { noremap = true })
