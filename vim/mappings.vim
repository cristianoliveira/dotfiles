let vimmappings = '~/.vim/mappings'
let uname = system("uname -s")

for fpath in split(globpath(vimmappings, '*.vim'), '\n')

  " if (fpath == expand(vimmappings) . "/yadr-keymap-mac.vim") && uname[:4] ==? "linux"
  "   continue " skip mac mappings for linux
  " endif

  " if (fpath == expand(vimmappings) . "/yadr-keymap-linux.vim") && uname[:4] !=? "linux"
  "   continue " skip linux mappings for mac
  " endif

  exe 'source' fpath
endfor
