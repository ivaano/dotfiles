set nocompatible
filetype off

call plug#begin()
    Plug 'sheerun/vim-polyglot'
    Plug 'Badacadabra/vim-archery'
    Plug 'cocopon/iceberg.vim'
    Plug 'arcticicestudio/nord-vim'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'jiangmiao/auto-pairs'
    Plug 'preservim/nerdtree'
    Plug 'preservim/tagbar'
    "Plug 'wakatime/vim-wakatime'
call plug#end()

filetype plugin indent on

set nu     " Enable line numbers
syntax on  " Enable syntax highlighting

" How many columns of whitespace a \t is worth
set tabstop=4
" How many columns of whitespace a "level of indentation" is worth
set shiftwidth=4
" Use spaces when tabbing
set expandtab

set incsearch  " Enable incremental search
set hlsearch   " Enable highlight search

set splitbelow
set mouse=

set t_Co=256
set t_AB=^[[48;5;%dm
set t_AF=^[[38;5;%dm
set termguicolors
set background=dark
set showtabline=2
set laststatus=2

try
    colorscheme nord
catch /^Vim\%((\a\+)\)\=:E185/
    silent! colorscheme default
endtry

let g:airline_theme = 'archery'
let g:AutoPairsShortcutToggle = '<C-P>'
nmap <F2> :NERDTreeToggle<CR>

" Focus the panel when opening it
let g:tagbar_autofocus = 1
" Highlight the active tag
let g:tagbar_autoshowtag = 1
" Make panel vertical and place on the right
let g:tagbar_position = 'botright vertical'
" Mapping to open and close the panel
nmap <F8> :TagbarToggle<CR>
