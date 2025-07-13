" Sample .vimrc configuration
" This is a demo file to show the editor category structure

" Basic settings
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

" Search settings
set hlsearch
set incsearch
set ignorecase
set smartcase

" UI settings
syntax on
colorscheme desert
set laststatus=2
set ruler
set showcmd

" Key mappings
let mapleader = ","
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Show line numbers
set number

echo "Sample editor configuration loaded!"
