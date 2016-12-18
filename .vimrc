execute pathogen#infect()

let mapleader = "\<Space>"

set nocompatible
filetype off
set foldmethod=marker
set linebreak

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

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 0 "change 0 to 1 if you have a powerline font
set laststatus=2
set t_Co=256

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

so ~/.vim/plugins.vim
so ~/.vim/settings/search.vim
so ~/.vim/settings/nerdtree.vim
so ~/.vim/settings/mappings.vim

colorscheme solarized
