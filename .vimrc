execute pathogen#infect()

let mapleader = "\<Space>"

set nocompatible
filetype off

set foldmethod=indent
set foldnestmax=5
set nofoldenable

" Breaks line when it doesn't feet on pane
" set linebreak

set number

syntax on
set mouse=a

filetype plugin indent on

set encoding=utf-8
set fileencodings=utf-8

set autoindent
set smartindent
set cindent
set background=dark
set expandtab
set smarttab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set wildignore=*.pyc
set ignorecase
set smartcase
set hlsearch
set incsearch
set shiftround
set history=1000
set undolevels=1000
set noswapfile
set nobackup
set number
set linespace=3

let g:windowswap_map_keys = 0 "prevent default bindings

set laststatus=2
set t_Co=256

" Delete works on insert mode
set backspace=indent,eol,start

" 80 columns
set colorcolumn=80

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

command! ReloadSettings :source ~/.vimrc
command! BuffersRefresh :bufdo e

so ~/.vim/plugins.vim
so ~/.vim/settings.vim

colorscheme solarized
