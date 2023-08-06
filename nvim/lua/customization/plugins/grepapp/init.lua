function Grepapp(args)
  io.popen("open https://grep.app/search?q=".. args)
end
vim.cmd("command! -nargs=1 Grepapp lua Grepapp(<f-args>)")
