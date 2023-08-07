require('customization/plugins')

require('customization/functions/selected_content')
require('customization/functions/vimscript_to_lua')
--
require('customization/mappings/ultisnips')
require('customization/mappings/copy_paste')
require('customization/mappings/visual_code_editing')
require('customization/mappings/git')
require('customization/mappings/fugitive')
require('customization/mappings/panels')
require('customization/mappings/defaults')
require('customization/mappings/lsp')
require('customization/mappings/buffers')
require('customization/mappings/tabs')
require('customization/mappings/macros')
require('customization/mappings/netrw')
require('customization/mappings/copilot')
require('customization/mappings/grep')
require('customization/mappings/ale')
require('customization/mappings/marks')
require('customization/mappings/find_replace')
--
require('customization/settings/vim')
require('customization/settings/lsp')
require('customization/settings/performance')
require('customization/settings/navigation')
require('customization/settings/projectionist')
require('customization/settings/ale')
require('customization/settings/intellisense')
--
-- js specific
-- const foo = require('customization/foo')
-- to
-- import foo from 'foo'
-- vim.keymap.set("v", "<leader>jsi", ':s/const\\(.*\\)=.*require(\\(.*\\))/import\\1from \\2', { noremap = true, silent = false })

-- create a command :FormatFromSnakeCaseToCamelCase that apply
-- '<,'>s#\C\(\<\u[a-z0-9]\+\|[a-z0-9]\+\)\(\u\)#\l\1_\l\2#g
-- to the selected lines
-- vim.keymap.set('customization/v', '<leader>fmsc', "'<,'>s#\\C\\(\\<\\u[a-z0-9]\\+\\|[a-z0-9]\\+\\)\\(\\u\\)#\\l\\1_\\l\\2#g", { noremap = true, silent = false })

-- test from_to

