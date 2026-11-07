-- Run from nvim/: nvim --headless --noplugin -u NONE -l tests/treesitter_spec.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local plugins = vim.fn.stdpath('data') .. '/lazy/'
vim.opt.runtimepath:append(plugins .. 'nvim-treesitter')
vim.opt.runtimepath:append(plugins .. 'nvim-treesitter-textobjects')

vim.g.mapleader = ' '
vim.cmd('filetype plugin indent on')
require('customization.settings.treesitter')

local function open_buffer(filetype, lines)
  vim.cmd.enew({ bang = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = filetype
  return vim.api.nvim_get_current_buf()
end

local function press(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'xt', false)
end

-- Markdown highlighting includes inline markup and fenced-code injections.
local markdown = open_buffer('markdown', {
  '# Example',
  '',
  '- Others: Check `nix/*` folder',
  '',
  '```lua',
  'local answer = 42',
  '```',
})
assert(vim.treesitter.highlighter.active[markdown], 'Markdown highlighting should start on FileType')
local parser = vim.treesitter.get_parser(markdown)
parser:parse(true)
assert(parser:children().markdown_inline, 'Markdown inline injection should parse')
assert(parser:children().lua, 'Markdown fenced Lua injection should parse')
vim.api.nvim_buf_set_lines(markdown, 2, 3, false, { '- Typescript & Javascript (`React` & Node)' })
parser:parse(true)
assert(parser:children().markdown_inline, 'Markdown injections should survive edits')

-- Lua indentation and function motions use the maintained APIs.
open_buffer('lua', {
  'local function first(alpha, beta)',
  '  return alpha + beta',
  'end',
  '',
  'local function second()',
  '  return 2',
  'end',
})
assert(vim.bo.indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()", 'Lua should use the new indent API')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
press(']m')
assert(vim.api.nvim_win_get_cursor(0)[1] == 5, ']m should jump to the next function')
press('[m')
assert(vim.api.nvim_win_get_cursor(0)[1] == 1, '[m should jump to the previous function')
press(']M')
assert(vim.api.nvim_win_get_cursor(0)[1] == 3, ']M should jump to the current function end')
press(']M')
assert(vim.api.nvim_win_get_cursor(0)[1] == 7, ']M should jump to the next function end')
press('[M')
assert(vim.api.nvim_win_get_cursor(0)[1] == 3, '[M should jump to the previous function end')

-- Parameter swaps and operator-pending selections still edit actual source.
vim.api.nvim_win_set_cursor(0, { 1, 22 })
press(' a')
assert(vim.api.nvim_get_current_line() == 'local function first(beta, alpha)', 'Swap should exchange parameters')
press(' A')
assert(vim.api.nvim_get_current_line() == 'local function first(alpha, beta)', 'Reverse swap should restore parameters')
press(' a')
vim.api.nvim_win_set_cursor(0, { 1, 28 })
press('dia')
assert(vim.api.nvim_get_current_line() == 'local function first(beta, )', 'dia should delete the inner parameter')

-- Incremental selection uses Neovim's native parent/child selection.
vim.api.nvim_win_set_cursor(0, { 2, 10 })
press('<C-Space>')
assert(vim.fn.mode() == 'v', 'Ctrl-Space should start a visual node selection')
local first_selection = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'))
press('<C-Space>')
local parent_selection = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'))
assert(not vim.deep_equal(first_selection, parent_selection), 'Ctrl-Space should grow the selection')
press('<M-Space>')
assert(vim.deep_equal(first_selection, vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'))),
  'Alt-Space should restore the child selection')
press('<C-s>')
assert(vim.deep_equal(parent_selection, vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'))),
  'Ctrl-S should select the parent node')
press('<Esc>')

-- Files without a parser retain ordinary editing without Tree-sitter errors.
local plain = open_buffer('not_a_parser', { 'plain text' })
assert(not vim.treesitter.highlighter.active[plain], 'Unsupported filetypes should not start highlighting')
assert(vim.bo.indentexpr == '', 'Unsupported filetypes should retain their default indentation')

print('treesitter_spec: ok')
