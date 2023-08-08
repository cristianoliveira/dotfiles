function nnoremap(map_keys, command)
  local opts = { noremap=true, silent=true }
  vim.api.nvim_set_keymap('n', map_keys, command, opts)
end

function vnoremap(map_keys, command)
  local opts = { noremap=true, silent=true }
  vim.api.nvim_set_keymap('v', map_keys, command, opts)
end

function nmap(map_keys, command)
  local opts = { noremap=false, silent=true }
  vim.api.nvim_set_keymap('n', map_keys, command, opts)
end

function vmap(map_keys, command)
  local opts = { noremap=false, silent=true }
  vim.api.nvim_set_keymap('v', map_keys, command, opts)
end

function cnoremap(map_keys, command)
  local opts = { noremap=true, expr=true }
  vim.api.nvim_set_keymap('c', map_keys, command, opts)
end
