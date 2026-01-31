-- Here is declared all Custom Commands, they all must start with C<Name>
--
require("customization/commands/obsidian")
require("customization/commands/vscode")
require("customization/commands/clipboard")
require("customization/commands/diffquickfix")
require("customization/commands/telescope")
require("customization/commands/visual-modes")

vim.cmd("command! -nargs=0 CFormat lua vim.lsp.buf.format()")

-- Usually when I am working on a project I have a script that I run over and over again
-- I take this and create a simple command to run it
-- with :Do
--
-- The folder `.scripts/` is in the root of the project and ignore by git
vim.cmd("command! -nargs=0 Do !bash .scripts/do.sh")

-- Fugitive
vim.cmd("command! -nargs=0 Gaf :G add %")

--Common linux command
--make current file executable
vim.cmd("command! -nargs=0 Chx :!chmod +x %")

--Format json file to pretty print
vim.cmd("command! -nargs=0 JSONFormat :%!python -m json.tool")

-- Edit nvim config
vim.cmd("command! -nargs=0 NvimEdit :e $MYVIMRC")

--Relaod nvim config command
vim.cmd("command! -nargs=0 NvimReload :source $MYVIMRC")

-- EXAMPLES
--
-- Command with completion
-- ```lua
--   vim.api.nvim_create_user_command("Greet", function(opts)
--     print("Hello, " .. opts.args)
--   end, {
--     nargs = 1,
--     complete = function(arg_lead, cmd_line, cursor_pos)
--       return { "Alice", "Bob", "Charlie" }
--     end
--   })
-- ```


