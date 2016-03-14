"Basics                                                                                                                                                         
    set nocompatible        " must be first line
    filetype off                   " required!

     set rtp+=~/.vim/bundle/vundle/
     call vundle#rc()

       " let Vundle manage Vundle
       "  " required! 
    Bundle 'gmarik/vundle'
    filetype plugin indent on     " required!

    "colorschemes
    Bundle 'flazz/vim-colorschemes'
    "status bar in stereoids
    Bundle 'Lokaltog/vim-powerline'
    "matchit
    Bundle 'matchit.zip'
    "Nerdtree
    Bundle 'scrooloose/nerdtree'
    "neocomplcache
    Bundle 'Shougo/neocomplcache'
    "Autoalign
    Bundle 'tsaleh/vim-align'
"General
"    set background=dark             " Assume a dark background
    if &term =~ "xterm" || &term =~ "screen.*"
        let &t_Co=256
        set background=dark
        "colorscheme jellybeans
        hi CursorLine cterm=none
    endif
    filetype plugin indent on       " Automatically detect file types.
    syntax on                       " Colorcitos
    scriptencoding utf-8
    set enc=utf-8                       " Use UTF-8 as the default buffer encoding
    " always switch to the current file directory.
    autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" | lcd %:p:h | endif 
    set viewoptions=folds,options,cursor,unix,slash " better unix / windows compatibility
    set history=1000                        " Store a ton of history (default is 20)

" VIm UI
    set showmatch                   " show matching brackets/parenthesis
    set incsearch                   " find as you type search
    set hlsearch                    " highlight search terms
    set number                      " Line Numbers on
    set ignorecase                  " case insensitive search
    set cursorcolumn                " highlight current column
    set cursorline                  " highlight current line
    set winminheight=0              " windows can be 0 line high
    set smartcase                   " case sensitive when uc present
    set wildmenu                    " show list instead of just completing
    set wildmode=list:longest,full  " command <Tab> completion, list matches, then longest common part, then all.
    set whichwrap=b,s,h,l,<,>,[,]   " backspace and cursor keys wrap to
    set scrolljump=5                " lines to scroll when cursor leaves screen
    set scrolloff=3                 " minimum lines to keep above and below cursor
    set foldenable                  " auto fold code
    " Highlight problematic whitespace
    "set list
    "set listchars=tab:,.,trail:.,extends:#,nbsp:. 
 
    "Statusbar
    set laststatus=2
 
    " Broken down into easily includeable segments
    set statusline=%<%f\                     " Filename
    set statusline+=%w%h%m%r                 " Options
    set statusline+=\ [%{&ff}/%Y]            " filetype
    set statusline+=\ [%{getcwd()}]          " current dir
    set statusline+=%=%-14.(%l,%c%V%)\ %p%%  " Right aligned file nav info
 
    "Command Line
    set ruler                   " show the ruler
    set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " a ruler on steroids
    set showcmd                 " show partial commands in status line and selected characters/lines in visual mode

    " Formatting   
    set nowrap                      " wrap long lines
    set autoindent                  " indent at the same level of the previous line
    "set smartindent                 "  automatically inserts one extra level of indentation in some cases, and works for C-like files
    set shiftwidth=4                " use indents of 4 spaces
    set expandtab                   " tabs are spaces, not tabs
    set tabstop=4                   " an indentation every four columns
    set softtabstop=4               
    set backspace=2
    set backspace=indent,eol,start  " let backspace delete indent
    "set matchpairs+=<:>            " match, to be used with %
    set pastetoggle=<F12>           " pastetoggle (sane indentation on pastes)

   "The default leader is '\', but many people prefer ',' as it's in a standard
    "location
    let mapleader = ','

    " NerdTree {
    map <C-e> :NERDTreeToggle<CR>:NERDTreeMirror<CR>
    map <leader>e :NERDTreeFind<CR>
    nmap <leader>nt :NERDTreeFind<CR>

    let NERDTreeShowBookmarks    = 1 
    let NERDTreeIgnore           = ['\.pyc', '\~$', '\.swo$', '\.swp$', '\.git', '\.hg', '\.svn', '\.bzr']
    let NERDTreeChDirMode        = 0 
    let NERDTreeQuitOnOpen       = 1 
    let NERDTreeShowHidden       = 1 
    let NERDTreeKeepTreeInNewTab = 1 
    " Functions
        function! NERDTreeInitAsNeeded()
        redir => bufoutput
        buffers!
        redir END 
        let idx = stridx(bufoutput, "NERD_tree")
        if idx > -1
            NERDTreeMirror
            NERDTreeFind
            wincmd l
        endif
    endfunction

    "neocomplcache {
    " Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplcache.
let g:neocomplcache_enable_at_startup = 1
" Use smartcase.
let g:neocomplcache_enable_smart_case = 1
" Use camel case completion.
let g:neocomplcache_enable_camel_case_completion = 1
" Use underbar completion.
let g:neocomplcache_enable_underbar_completion = 1
" Set minimum syntax keyword length.
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplcache_dictionary_filetype_lists = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
    \ }

" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
  let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
imap <C-k>     <Plug>(neocomplcache_snippets_expand)
smap <C-k>     <Plug>(neocomplcache_snippets_expand)
inoremap <expr><C-g>     neocomplcache#undo_completion()
inoremap <expr><C-l>     neocomplcache#complete_common_string()

" SuperTab like snippets behavior.
"imap <expr><TAB> neocomplcache#sources#snippets_complete#expandable() ? "\<Plug>(neocomplcache_snippets_expand)" : pumvisible() ? "\<C-n>" : "\<TAB>"

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <expr><CR>  neocomplcache#smart_close_popup() . "\<CR>"
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()

" AutoComplPop like behavior.
"let g:neocomplcache_enable_auto_select = 1

" Shell like behavior(not recommended).
"set completeopt+=longest
"let g:neocomplcache_enable_auto_select = 1
"let g:neocomplcache_disable_auto_complete = 1
"inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<TAB>"
"inoremap <expr><CR>  neocomplcache#smart_close_popup() . "\<CR>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif
let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'
"autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplcache_omni_patterns.c = '\%(\.\|->\)\h\w*'
let g:neocomplcache_omni_patterns.cpp = '\h\w*\%(\.\|->\)\h\w*\|\h\w*::'

noremap <silent> <C-S>          :update<CR>
vnoremap <silent> <C-S>         <C-C>:update<CR>
inoremap <silent> <C-S>         <C-O>:update<CR>
