-- follow link within [[filepath]] and consider it as filepath.md
-- [[example1]] -> example1.md
-- [[example2|text]] -> example2.md
-- [[2023-10-05|yesterday]] -> 2023-10-05.md
local obsmd = vim.api.nvim_create_augroup('ObsMarkdown', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  callback = function()

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
