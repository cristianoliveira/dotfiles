" Minimal sane configuration for tiny-vim
"----
" Tab vs spaces 
set softtabstop=2 " Tab is 2 spaces
set tabstop=2 " Tab is 2 spaces
set expandtab " Use spaces instead of tabs

" Indentation
set autoindent " Copy indent from current line
set shiftwidth=2 " Indent with 2 spaces

set nocompatible " Use Tab for completion
set backspace=indent,eol,start " Backspace through everything in insert mode
set history=100 " Keep 100 lines of command line history

set ruler " Show the cursor position all the time
set showcmd " Show incomplete commands

set number " Show line numbers
