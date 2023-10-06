-- follow link within [[filepath]] and consider it as filepath.md
-- [[example1]] -> example1.md
-- [[example2|text]] -> example2.md
-- [[2023-10-05|yesterday]] -> 2023-10-05.md
vim.keymap.set('n', '<leader>ol', function()
  local line = vim.fn.getline('.')
  local file = string.match(line, '%[%[(.*)%]%]')
  print(file)
  if file.find(file, '|') then
    file = string.match(file, '(.*)|.*')
    print("formatted: " .. file)
  end
  if file then
    vim.cmd('e ' .. file .. '.md')
  end
end, { noremap = true, silent = true, desc = '[o]bsidian [l]ink' })
