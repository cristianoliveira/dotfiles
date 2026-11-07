local treesitter = require('nvim-treesitter')
treesitter.setup {}
treesitter.install {
  'c', 'cpp', 'go', 'javascript', 'lua', 'markdown', 'markdown_inline',
  'python', 'rust', 'tsx', 'typescript', 'vimdoc', 'vim', 'nix',
}

local group = vim.api.nvim_create_augroup('customization.treesitter', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function(event)
    local language = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
    if not language or not vim.treesitter.language.add(language) then
      return
    end

    vim.treesitter.start(event.buf, language)
    if vim.treesitter.query.get(language, 'indents') then
      vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Neovim 0.12 replaces the removed incremental-selection module.
vim.keymap.set({ 'n', 'x' }, '<C-Space>', function()
  vim.treesitter.select('parent')
end, { desc = 'Select parent syntax node' })
vim.keymap.set('x', '<M-Space>', function()
  vim.treesitter.select('child')
end, { desc = 'Select child syntax node' })
-- The old scope-selection key now expands to the parent syntax node.
vim.keymap.set('x', '<C-s>', function()
  vim.treesitter.select('parent')
end, { desc = 'Select parent syntax node' })

require('nvim-treesitter-textobjects').setup {
  select = { lookahead = true },
  move = { set_jumps = true },
}

local select = require('nvim-treesitter-textobjects.select')
for key, capture in pairs {
  aa = '@parameter.outer',
  ia = '@parameter.inner',
  af = '@function.outer',
  ['if'] = '@function.inner',
  ac = '@class.outer',
  ic = '@class.inner',
} do
  vim.keymap.set({ 'x', 'o' }, key, function()
    select.select_textobject(capture, 'textobjects')
  end, { desc = 'Select ' .. capture })
end

local move = require('nvim-treesitter-textobjects.move')
for method, mappings in pairs {
  goto_next_start = { [']m'] = '@function.outer', [']]'] = '@class.outer' },
  goto_next_end = { [']M'] = '@function.outer', [']['] = '@class.outer' },
  goto_previous_start = { ['[m'] = '@function.outer', ['[['] = '@class.outer' },
  goto_previous_end = { ['[M'] = '@function.outer', ['[]'] = '@class.outer' },
} do
  for key, capture in pairs(mappings) do
    vim.keymap.set({ 'n', 'x', 'o' }, key, function()
      move[method](capture, 'textobjects')
    end, { desc = method .. ' ' .. capture })
  end
end

local swap = require('nvim-treesitter-textobjects.swap')
vim.keymap.set('n', '<leader>a', function()
  swap.swap_next('@parameter.inner')
end, { desc = 'Swap next parameter' })
vim.keymap.set('n', '<leader>A', function()
  swap.swap_previous('@parameter.inner')
end, { desc = 'Swap previous parameter' })
