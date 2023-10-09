-- follow link within [[filepath]] and consider it as filepath.md
-- [[example1]] -> example1.md
-- [[example2|text]] -> example2.md
-- [[2023-10-05|yesterday]] -> 2023-10-05.md

local is_vault = function () 
  return vim.fn.isdirectory('.obsidian') == 1
end

local obsmd = vim.api.nvim_create_augroup('ObsMarkdown', { clear = true })
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if not is_vault() then return end

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
    if not is_vault() then return end

    vim.keymap.set('n', 'gf', function()
      local line = vim.fn.getline('.')
      -- fallback to default gf if not obsidian link
      if line.find(line, '%[%[') == nil then
        vim.cmd('normal! gf')
        return
      end

      local file = string.match(line, '%[%[(.*)%]%]')
      if file then
        if file.find(file, '|') then
          file = string.match(file, '(.*)|.*')
        end

        vim.cmd('e ' .. file .. '.md')
      end
    end, { noremap = true, desc = '[o]bsidian [l]ink' })

    -- Open daily note at $PWD/daily/dd-mm-yyyy.md
    vim.keymap.set('n', '<leader>odn', function()
      local date = os.date('%d-%m-%Y')

      vim.cmd('e daily/' .. date .. '.md')
    end, { noremap = true, desc = '[t]o [t]o[d]o' })

    -- mark a todo as done
    -- [ ] foobar -> [x] foobar
    vim.keymap.set('n', '<leader>ttc', function()
      local current_line_number = vim.fn.line('.')
      local line = vim.fn.getline(current_line_number)

      local done = string.match(line, '%[x%]')
      if done then
        line = string.gsub(line, '%[x%]', '[ ]', 1)
      else
        line = string.gsub(line, '%[ %]', '[x]', 1)
      end

      vim.fn.setline(current_line_number, line)
    end, { noremap = true, desc = '[t]o [t]odo [c]hange' })

    -- Create a todo from a plain text
    vim.keymap.set('n', '<leader>ttd', function()
      local current_line_number = vim.fn.line('.')
      local line = vim.fn.getline(current_line_number)

      local is_todo = string.match(line, '%- %[%D?%]')
      if is_todo then
        line = string.gsub(line, '- %[%D?%]', '', 1)
      else
        line = '- [ ]' .. line
      end
      vim.fn.setline(current_line_number, line)
    end, { noremap = true, desc = '[t]o [t]o[d]o' })

  end,
  group = obsmd,
  pattern = 'markdown',
})
