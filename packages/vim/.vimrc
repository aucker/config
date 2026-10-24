" Lightweight fallback editor. Neovim is configured separately.
set nocompatible
filetype plugin indent on
syntax enable
set encoding=utf-8

" Display and editing: keep two-column tabs and familiar navigation.
set number ruler
set noexpandtab tabstop=2 shiftwidth=2 softtabstop=2 autoindent
set backspace=indent,eol,start
set list listchars=tab:\|\ ,trail:▫
set scrolloff=4
set wrap textwidth=0
set splitright splitbelow
set laststatus=2 showcmd
set statusline=%f\ %m%r%h%w%=%l:%c\ %p%%
set background=dark

" Search and built-in filename completion.
set hlsearch incsearch ignorecase smartcase showmatch
set wildmenu wildmode=longest,list,full
set wildignore=log/**,node_modules/**,target/**,tmp/**,*.rbc

let mapleader = ' '
nnoremap ; :
nnoremap Q :q<CR>
nnoremap S :w<CR>
nnoremap <Leader>rc :edit ~/.vimrc<CR>
nnoremap <Leader>sr :%s/
nnoremap <Leader><CR> :nohlsearch<CR>
nnoremap <Leader>sc :setlocal spell!<CR>
nnoremap = nzz
nnoremap - Nzz
nnoremap K 5k
nnoremap J 5j
nnoremap N 0
nnoremap W 5w
nnoremap B 5b
nnoremap <C-U> 5<C-Y>
nnoremap <C-E> 5<C-E>

" Splits and Vim's built-in file browser (netrw).
nnoremap sk :aboveleft split<CR>
nnoremap sj :belowright split<CR>
nnoremap sh :aboveleft vsplit<CR>
nnoremap sl :belowright vsplit<CR>
nnoremap nt :Explore<CR>

" Native clipboard, with an ordinary yank on Vim builds without support.
if has('clipboard')
  xnoremap Y "+y
else
  xnoremap Y y:<C-U>echo 'System clipboard unavailable; selection yanked in Vim'<CR>
endif

" C/C++ formatting is optional and never installs tools at startup.
command! Format call dotfiles#format_manual()
nnoremap <silent> <C-K> :Format<CR>
augroup dotfiles_clang_format
  autocmd!
  autocmd BufWritePre *.h,*.cc,*.cpp call dotfiles#format()
augroup END

" Restore the last cursor position without duplicating hooks on reload.
augroup dotfiles_vim
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g`\"" | endif
augroup END
