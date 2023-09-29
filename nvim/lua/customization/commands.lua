-- Here is declared all Custom Commands, they all must start with C<Name>

vim.cmd("command! -nargs=0 CFormat lua vim.lsp.buf.format()")
