-- Here is declared all Custom Commands, they all must start with C<Name>
--
require("customization/commands/obsidian")

vim.cmd("command! -nargs=0 CFormat lua vim.lsp.buf.format()")

vim.cmd("command! -nargs=0 NvimEdit :e $MYVIMRC")
