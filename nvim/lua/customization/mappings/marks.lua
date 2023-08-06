nmap("<leader>mm", ":mark ")
-- Go to mark
nmap("<leader>m1", "g'1")
nmap("<leader>m2", "g'2")
nmap("<leader>m3", "g'3")

local currmark = '1'
vim.keymap.set('n', '<leader>mn',function ()
  local cmd = "g\'" .. currmark

  vim.cmd(cmd)
  if currmark == '1' then
    currmark = '2'
  elseif currmark == '2' then
    currmark = '1'
  end
    
  print('ffffffffffffffffffffffffffffffffffffff' .. currmark)
end, { expr = true })
