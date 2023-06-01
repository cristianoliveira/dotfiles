function Funzzy_newtab(target)
  vim.cmd("tabnew")
  if target ~= "" then
    vim.cmd(":ter funzzy --non-block --target \"" .. target .. "\"")
    return
  end

  vim.cmd(":ter funzzy --non-block")
end

vim.cmd("command! -nargs=1 FunzzyTab lua Funzzy_newtab(<f-args>)")

function Funzzy(target)
  if target ~= "" then
    vim.cmd(":ter funzzy --non-block --target \"" .. target .. "\"")
    return
  end

  vim.cmd(":ter funzzy --non-block")
end
vim.cmd("command! -nargs=1 Funzzy lua Funzzy(<f-args>)")


vim.keymap.set("n", "<leader>fnz", 'Funzzy ', { script = true, silent = false })
vim.keymap.set("n", "<leader>fnt", 'FunzzyTab ', { script = true, silent = false })
