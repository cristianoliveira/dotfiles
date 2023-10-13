-- Open daily note at $PWD/daily/dd-mm-yyyy.md
local M = {}

M.is_vault = function () 
  return vim.fn.isdirectory('.obsidian') == 1
end

M.open_daily_note = function()
  if not M.is_vault() then return end

  local date = os.date('%d-%m-%Y')

  vim.cmd('e daily/' .. date .. '.md')
end

M.jump_to_link = function()
    if not M.is_vault() then return end

    local line = vim.fn.getline('.')

    -- follow markdown links like [link](./foo bar/file.md) with vi(gf
    if line.find(line, '%[.*%]%(.*%)') then
      print('found markdown link', line)
      vim.cmd('normal! vi(gf')
      return
    end

    -- follow obsidian links like [[file]] or [[file|description]]
    local file = string.match(line, '%[%[(.*)%]%]')
    if file then
      if file.find(file, '|') then
        file = string.match(file, '(.*)|.*')
      end

      -- If file is a directory, open it index.md instead
      if vim.fn.isdirectory(file) == 1 then
        file = file .. '/index'
      end

      vim.cmd('e ' .. file .. '.md')
      return
    end

    vim.cmd('normal! gf')
end

-- A todo item is
--  - [ ] task to be done
--  - [x] task done
M.toggle_todo_item = function()
  local current_line_number = vim.fn.line('.')
  local line = vim.fn.getline(current_line_number)

  local done = string.match(line, '%[x%]')
  if done then
    line = string.gsub(line, '%[x%]', '[ ]', 1)
  else
    line = string.gsub(line, '%[ %]', '[x]', 1)
  end

  vim.fn.setline(current_line_number, line)
end

-- Using telescope to search tags #tag
M.search_tags = function()
  require('telescope.builtin').grep_string({ search = "#" .. vim.fn.expand("<cword>") })
end

M.collect_tags = function(tag)
  vim.cmd("read !obsh tag " .. tag)
end

vim.cmd("command! -nargs=0 ObsOpenDaily lua require('customization/commands/obsidian').open_daily_note()")
vim.cmd("command! -nargs=0 ObsTodoToggle lua require('customization/commands/obsidian').toggle_todo_item()")
vim.cmd("command! -nargs=0 ObsGotoFile lua require('customization/commands/obsidian').jump_to_link()")
vim.cmd("command! -nargs=0 ObsLink lua require('customization/commands/obsidian').jump_to_link()")
vim.cmd("command! -nargs=0 ObsSearchTags lua require('customization/commands/obsidian').search_tags()")
vim.cmd("command! -nargs=1 ObsCollectTags lua require('customization/commands/obsidian').collect_tags(<f-args>)")

return M
