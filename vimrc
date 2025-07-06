vim9script

:set number
:set autoindent
:set smartindent
:set undofile
:set ttimeout
:set autowrite
:set ignorecase
:set wildmenu
:set smartcase
:set noshowmode
:set hlsearch
:set shortmess+=c
:set spelllang+=cjk

:nohlsearch
:syntax on
:colorscheme catppuccin
:filetype plugin indent on

&ttimeoutlen = 50
&scrolloff = 99
&pumheight = 15
&shiftwidth = 4
&softtabstop = 4
&laststatus = 3
&updatetime = 300
&completeslash = "slash"
&completeopt = "menuone,noinsert,noselect,fuzzy,popup,preview"
&completeitemalign = "kind,abbr,menu"
&showbreak = "↪ "
&fillchars = 'eob: '
&signcolumn = "yes"

var state_dir = has('win32') || has('win64')
    ? $LOCALAPPDATA .. '/vim'
    : ($XDG_STATE_HOME !=# ''
	? $XDG_STATE_HOME .. '/vim'
	: expand('~/.local/state/vim'))

if !isdirectory(state_dir)
    mkdir(state_dir, 'p')
endif

&backupdir = state_dir .. '//'
&undodir   = state_dir .. '//'

g:mapleader = " "

if has('gui_running')
    set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50
else
    &t_SI = "\e[6 q"
    &t_EI = "\e[2 q"
    &t_SR = "\e[4 q"
endif

if exists("+comments")
    packadd comment
endif

if exists("+comments")
    packadd comment
endif

packadd cfilter
