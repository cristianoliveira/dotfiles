vim.g.codeium_manual = 0
vim.g.codeium_disable_bindings = 1

vim.b.copilot_enabled = false

vim.keymap.set('i', '<Tab>', function () return vim.fn['codeium#Accept']() end, { expr = true, script = true })
vim.keymap.set('i', '<C-q>', function() return vim.fn['codeium#Complete']() end, { expr = true, script = true })
vim.keymap.set('i', '<C-h>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, script = true })
vim.keymap.set('i', '<C-x>', function() return vim.fn['codeium#Clear']() end, { expr = true, script = true })
