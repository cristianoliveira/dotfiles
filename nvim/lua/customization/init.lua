--> Plugins custom settings

--> Local plugins
require('customization/plugins')

--> Custom Commands
require('customization/autocmds')
require('customization/commands')
require('customization/commands/obsidian')

--> Helper functions
require('customization/functions/vimscript_to_lua')

--> Mappings
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
require('customization/mappings/grep')
require('customization/mappings/marks')
require('customization/mappings/find_replace')
require('customization/mappings/telescope')
require('customization/mappings/obsidian')
require('customization/mappings/curl')
require('customization/mappings/argpoon')

-- require('customization/mappings/copilot')
require('customization/mappings/codeium')

--> Settings
require('customization/settings/lsp')
require('customization/settings/projectionist')
require('customization/settings/intellisense')
require('customization/settings/curl')
