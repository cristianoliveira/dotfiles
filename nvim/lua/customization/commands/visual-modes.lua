-- Visual Modes Manager
-- Manages visual mode presets (Default, Pairing, Focus, etc.)
-- Provides commands to switch modes and toggle settings.

local M = {}

-- Mode definitions
local modes = {
  default = {
    name = "Default",
    transparency = true,
    numbers = "relative",
    description = "Transparent background with relative line numbers"
  },
  pairing = {
    name = "Pairing",
    transparency = false,
    numbers = "absolute",
    description = "Opaque background with absolute line numbers (for pairing sessions)"
  },
  focus = {
    name = "Focus",
    transparency = false,
    numbers = "relative",
    description = "Opaque background with relative line numbers (focused work)"
  }
}

-- State
local current_mode_id = "default"
local transparent_enabled = true
local relative_numbers_enabled = true

-- Helper to apply transparency
local function apply_transparency(enable)
  if enable then
    vim.cmd([[highlight Normal guibg=none ctermbg=none]])
    vim.cmd([[highlight NonText guibg=none ctermbg=none]])
    transparent_enabled = true
  else
    -- Re-apply colorscheme to reset highlights
    local colors_name = vim.g.colors_name or 'solarized'
    vim.cmd('colorscheme ' .. colors_name)
    transparent_enabled = false
  end
end

-- Helper to apply number mode
local function apply_numbers(mode)
  local value = mode == "relative"
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      vim.api.nvim_win_set_option(win, 'relativenumber', value)
    end
  end
  relative_numbers_enabled = value
end

-- Apply a visual mode (set transparency and numbers)
local function apply_mode(mode_id)
  local mode = modes[mode_id]
  if not mode then
    print("Error: Unknown mode '" .. mode_id .. "'")
    return
  end
  apply_transparency(mode.transparency)
  apply_numbers(mode.numbers)
  current_mode_id = mode_id
  print("Visual mode: " .. mode.name .. " (" .. mode.description .. ")")
end

-- List all available modes
local function list_modes()
  print("Available visual modes:")
  for id, mode in pairs(modes) do
    local marker = (id == current_mode_id) and "→ " or "  "
    print(string.format("  %s%s: %s", marker, mode.name, mode.description))
  end
end

-- Completion function for VisualMode command
local function complete_modes(ArgLead, CmdLine, CursorPos)
  local completions = {}
  for id, _ in pairs(modes) do
    table.insert(completions, id)
  end
  return completions
end

-- Switch to a specific mode by name (case-insensitive)
local function switch_mode(name)
  local lower = string.lower(name)
  for id, mode in pairs(modes) do
    if string.lower(mode.name) == lower or id == lower then
      apply_mode(id)
      return
    end
  end
  print("Error: Mode '" .. name .. "' not found. Use :VisualModesList to see available modes.")
end

-- Cycle through modes (toggle)
local function cycle_mode()
  local ids = {}
  for id, _ in pairs(modes) do
    table.insert(ids, id)
  end
  table.sort(ids) -- ensure consistent order
  local current_index = 1
  for i, id in ipairs(ids) do
    if id == current_mode_id then
      current_index = i
      break
    end
  end
  local next_index = (current_index % #ids) + 1
  apply_mode(ids[next_index])
end

-- Toggle transparency (independent of mode)
local function toggle_transparency()
  apply_transparency(not transparent_enabled)
  -- Update current mode to custom? Not for now.
  print("Transparency " .. (transparent_enabled and "enabled" or "disabled"))
end

-- Toggle number mode (independent of mode)
local function toggle_numbers()
  local new_mode = relative_numbers_enabled and "absolute" or "relative"
  apply_numbers(new_mode)
  print("Line numbers: " .. new_mode)
end

-- Initialize with default mode (should match autocmds.lua)
-- Note: autocmds.lua already sets transparency on VimEnter.
-- We'll ensure consistency by applying default mode on startup.
local function initialize()
  -- Apply default mode settings (transparency already set by autocmds.lua)
  -- Just set numbers to relative
  apply_numbers("relative")
end

-- Create user commands
vim.api.nvim_create_user_command('VisualModesList', list_modes,
  { desc = 'List all available visual modes' })

vim.api.nvim_create_user_command('VisualMode', function(opts)
  if opts.args and opts.args ~= "" then
    switch_mode(opts.args)
  else
    cycle_mode()
  end
end, { desc = 'Switch to a visual mode (or cycle if no argument)', nargs = '?', complete = complete_modes })

vim.api.nvim_create_user_command('Vs', function(opts)
  if opts.args and opts.args ~= "" then
    switch_mode(opts.args)
  else
    cycle_mode()
  end
end, { desc = 'Alias for VisualMode', nargs = '?', complete = complete_modes })

vim.api.nvim_create_user_command('Vsm', function(opts)
  if opts.args and opts.args ~= "" then
    switch_mode(opts.args)
  else
    cycle_mode()
  end
end, { desc = 'Vsm - Alias for VisualMode', nargs = '?', complete = complete_modes })

-- Run initialization
initialize()

return M
