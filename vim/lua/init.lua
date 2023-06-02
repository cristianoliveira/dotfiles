require('plugins')

require('functions/selected_content')
require('functions/vimscript_to_lua')

require('mappings/copy_paste')
require('mappings/visual_code_editing')
require('mappings/git')
require('mappings/fugitive')
require('mappings/panels')
require('mappings/defaults')
require('mappings/lsp')
require('mappings/buffers')
require('mappings/tabs')
require('mappings/macros')
require('mappings/netrw')
require('mappings/copilot')
require('mappings/ultisnips')
require('mappings/grep')
require('mappings/ale')

require('settings/vim')
require('settings/lsp')
require('settings/performance')
require('settings/navigation')
require('settings/projectionist')
require('settings/ale')

-- js specific
-- const foo = require('foo')
-- to
-- import foo from 'foo'
vim.keymap.set("v", "<leader>jsi", ':s/const\\(.*\\)=.*require(\\(.*\\))/import\\1from \\2', { noremap = true, silent = false })

-- create a command :FormatFromSnakeCaseToCamelCase that apply
-- '<,'>s#\C\(\<\u[a-z0-9]\+\|[a-z0-9]\+\)\(\u\)#\l\1_\l\2#g
-- to the selected lines
vim.keymap.set('v', '<leader>fmsc', "'<,'>s#\\C\\(\\<\\u[a-z0-9]\\+\\|[a-z0-9]\\+\\)\\(\\u\\)#\\l\\1_\\l\\2#g", { noremap = true, silent = false })

-- test from_to

