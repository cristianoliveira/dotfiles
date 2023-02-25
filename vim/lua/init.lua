local function nnoremap(map_keys, command)
  local opts = { noremap=true, silent=true }
  vim.api.nvim_set_keymap('n', map_keys, command, opts)
end

require('settings/lsp')
require('settings/performance')

require('mappings/visual_code_editing')
