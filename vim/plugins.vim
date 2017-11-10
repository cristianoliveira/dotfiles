set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/vundle'

Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'wesQ3/vim-windowswap'
Plugin 'ervandew/supertab'
Plugin 'gcmt/wildfire.vim'
Plugin 'Yggdroot/indentLine'

" Appearance
Plugin 'altercation/vim-colors-solarized'
Plugin 'sheerun/vim-polyglot'
Plugin 'vim-scripts/wombat256.vim'
Plugin 'bling/vim-airline'

" Autocomplete
Plugin 'ConradIrwin/vim-bracketed-paste'
Plugin 'tpope/vim-repeat.git'

" Ctags integration
Plugin 'craigemery/vim-autotag'

" Edition plugins
Plugin 'kristijanhusak/vim-multiple-cursors'

" Syntatic and Linter
Plugin 'vim-syntastic/syntastic'
Plugin 'tpope/vim-endwise'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'
Plugin 'joom/vim-commentary'
Plugin 'tpope/vim-surround'
Plugin 'jiangmiao/auto-pairs'
Plugin 'valloric/MatchTagAlways'


" Git integration
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'

" Navigation open file directs on line by `:e ./spec/test_spec.rb:16`
Plugin 'kopischke/vim-fetch'
" Plugin 'scrooloose/nerdtree'
Plugin 'juanibiapina/vim-lighttree'
Plugin 'jistr/vim-nerdtree-tabs'

" Search plugins
Plugin 'mileszs/ack.vim'
Plugin 'ctrlpvim/ctrlp.vim'

" Documentation
Plugin 'rizzatti/dash.vim'

" Languages
" Ruby
Plugin 'tpope/vim-rails'
Plugin 'thoughtbot/vim-rspec'

" Javascript
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'epilande/vim-es2015-snippets'
Plugin 'epilande/vim-react-snippets'
Plugin 'cristianoliveira/vim-react-html-snippets'
Plugin 'SirVer/ultisnips'

" Rust
Plugin 'rust-lang/rust.vim'

" Golang
Plugin 'fatih/vim-go'

call vundle#end()            " required
filetype plugin indent on
