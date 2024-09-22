-- Here is declared all Custom Commands, they all must start with C<Name>
--
require("customization/commands/obsidian")

vim.cmd("command! -nargs=0 CFormat lua vim.lsp.buf.format()")

vim.cmd("command! -nargs=0 NvimEdit :e $MYVIMRC")


-- Usually when I am working on a project I have a script that I run over and over again
-- I take this and create a simple command to run it
-- with :Do
--
-- The folder `_scripts` is in the root of the project and ignore by git
vim.cmd("command! -nargs=0 Do !bash _scripts/do.sh")

-- Fugitive
vim.cmd("command! -nargs=0 Gaf :G add %")

--Common linux command
--make current file executable
vim.cmd("command! -nargs=0 Chx :!chmod +x %")
