local function open_panel(opts)
  if opts.tab then
    vim.cmd("tabnew")
    return
  end

  if opts.split == "v" then
    vim.cmd("botright :vsplit")
    return
  end

  if opts.split == "s" then
    vim.cmd("botright :split")
    return
  end
end

function Funzzy(opts)
  open_panel(opts)

  if opts.target ~= "" then
    vim.cmd.terminal("funzzy --non-block --target \"" .. opts.target .. "\"")
    return
  end

  vim.cmd.terminal("funzzy --non-block")
end

function FunzzyCmd(opts)
  open_panel(opts)

  -- get current file directory
  local current_pwd = vim.fn.expand('%:p:h')
  local find_in_dir = "find -d ".. current_pwd .." -depth 1"
  -- :h Bar
  vim.cmd.terminal(find_in_dir .." | funzzy " .. opts.command .. " --non-block")
end

function FunzzyEdit(opts)
  if vim.fn.filereadable(".watch.yaml") == 0 then
    -- ask if user want to create .watch.yaml
    local create_answer = vim.fn.confirm("Funzzy: .watch.yaml was not found. Create for this directory?", "&Yes\n&No")
    if create_answer == 2 then
      return
    end

    vim.cmd("! funzzy init")
    while vim.fn.filereadable(".watch.yaml") == 0 do
      vim.cmd("sleep 1")
    end
  end

  open_panel(opts)
  vim.cmd.edit(".watch.yaml")
end

vim.cmd("command! -nargs=0 FunzzyEdit lua FunzzyEdit({ split = 'v' })", { expr = true })

vim.cmd("command! -nargs=* Funzzy lua Funzzy({ target = '<f-args>', tab = false })", { expr = true })
vim.cmd("command! -nargs=1 FunzzyCmd lua FunzzyCmd({ command = '<f-args>', tab = false })", { expr = true })

vim.cmd("command! -nargs=* FunzzyTab lua Funzzy({ target = '<f-args>', tab = true })", { expr = true })
vim.cmd("command! -nargs=1 FunzzyTabCmd lua FunzzyCmd({ command = '<f-args>', tab = true })", { expr = true })

vim.cmd("command! -nargs=* FunzzySplit lua Funzzy({ target = '<f-args>', split = 's' })", { expr = true })
vim.cmd("command! -nargs=1 FunzzySplitCmd lua FunzzyCmd({ command = '<f-args>', split = 's' })", { expr = true })

vim.cmd("command! -nargs=* FunzzyVplit lua Funzzy({ target = '<f-args>', split = 'v' })", { expr = true })
vim.cmd("command! -nargs=1 FunzzyVplitCmd lua FunzzyCmd({ command = '<f-args>', split = 'v' })", { expr = true })
