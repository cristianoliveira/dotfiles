-- follow link within [[filepath]] and consider it as filepath.md
-- [[example1]] -> example1.md
-- [[example2|text]] -> example2.md
-- [[2023-10-05|yesterday]] -> 2023-10-05.md
local obn = require('customization/commands/obsidian')

local obsmd = vim.api.nvim_create_augroup('ObsMarkdown', { clear = true })
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if not obn.is_vault() then return end

    local date = os.date('%d-%m-%Y')
    local daily_note = 'daily/' .. date .. '.md'

    -- if current buffer is the daily note, do nothing
    local current_buffer = vim.fn.expand('%:p')
    print(current_buffer)
    if vim.fn.expand('%:p') == daily_note then
      return
    end
    vim.cmd('e ' .. daily_note)
  end,
  group = obsmd,
  pattern = '*',
})

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    if not obn.is_vault() then return end

    vim.keymap.set('n', 'gf', ':ObsGotoFile <CR>', { noremap = true, desc = 'Obsidian [G]oto[F]ile' })
    vim.keymap.set('n', '<leader>odn', ':ObsOpenDaily', { noremap = true, desc = '[O]sidian [d]aily [n]ote' })
    vim.keymap.set('n', '<leader>ott', ':ObsTodoToggle', { noremap = true, desc = '[O]sidian [t]oggle [t]odo' })

    -- Create a todo from a plain text
    vim.keymap.set('n', '<leader>oct', function()
      local current_line_number = vim.fn.line('.')
      local line = vim.fn.getline(current_line_number)

      local is_todo = string.match(line, '%- %[%D?%]')
      if is_todo then
        line = string.gsub(line, '- %[%D?%]', '', 1)
      else
        line = '- [ ]' .. line
      end
      vim.fn.setline(current_line_number, line)
    end, { noremap = true, desc = '[O]bsidian [c]reate [t]odo' })

  end,
  group = obsmd,
  pattern = 'markdown',
})
