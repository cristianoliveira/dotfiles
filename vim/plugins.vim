set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/vundle'

Plugin 'bling/vim-airline'
Plugin 'bkad/CamelCaseMotion'
Plugin 'valloric/MatchTagAlways'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'wesQ3/vim-windowswap'
Plugin 'ervandew/supertab'
Plugin 'gcmt/wildfire.vim'
Plugin 'Yggdroot/indentLine'

"Apparecene
Plugin 'altercation/vim-colors-solarized'
Plugin 'sheerun/vim-polyglot'

"Autocomplete
Plugin 'ConradIrwin/vim-bracketed-paste'

"Close structures like `def foo; end` automatically
Plugin 'tpope/vim-endwise'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'
Plugin 'joom/vim-commentary'
Plugin 'tpope/vim-surround'
Plugin 'jiangmiao/auto-pairs'

"Color Schemes
Plugin 'vim-scripts/wombat256.vim'

"Ctags integration
Plugin 'craigemery/vim-autotag'

"Edition plugins
Plugin 'kristijanhusak/vim-multiple-cursors'

"Front End
Plugin 'pangloss/vim-javascript'

"Git integration
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'

"Navigation open file directs on line by `:e ./spec/test_spec.rb:16`
Plugin 'kopischke/vim-fetch'
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'

"Search plugins
Plugin 'rking/ag.vim'
Plugin 'ctrlpvim/ctrlp.vim'

call vundle#end()            " required
filetype plugin indent on
