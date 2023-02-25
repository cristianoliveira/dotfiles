let vimsettings = '~/.vim/settings'
let uname = system("uname -s")

for fpath in split(globpath(vimsettings, '*.vim'), '\n')
  exe 'source' fpath
endfor
