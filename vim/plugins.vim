set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/vundle'

Plugin 'scrooloose/nerdtree'
Plugin 'bling/vim-airline'
Plugin 'bkad/CamelCaseMotion'
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'
Plugin 'kristijanhusak/vim-multiple-cursors'
Plugin 'joom/vim-commentary'
Plugin 'valloric/MatchTagAlways'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'
Plugin 'jiangmiao/auto-pairs'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'wesQ3/vim-windowswap'
Plugin 'tpope/vim-surround'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'ervandew/supertab'
Plugin 'ConradIrwin/vim-bracketed-paste'
Plugin 'gcmt/wildfire.vim'
Plugin 'Yggdroot/indentLine'
Plugin 'rking/ag.vim'
Plugin 'sheerun/vim-polyglot'

"Provides open file directs on line by `:e ./spec/test_spec.rb:16`
Plugin 'kopischke/vim-fetch'

"Front End
Plugin 'pangloss/vim-javascript'

"Color Schemes
Plugin 'vim-scripts/wombat256.vim'

"Close structures like `def foo; end` automatically
Plugin 'tpope/vim-endwise'

"Apparecene
Plugin 'altercation/vim-colors-solarized'

call vundle#end()            " required
filetype plugin indent on
