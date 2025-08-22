vim9script

import autoload 'path.vim'

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
:set dir-=.

:nohlsearch
:colorscheme catppuccin
:filetype plugin indent on
:syntax on

&ttimeoutlen = 50
&scrolloff = 99
&pumheight = 15
&shiftwidth = 4
&softtabstop = 4
&tabstop = 4
&laststatus = 2
&updatetime = 300
&completeslash = "slash"
&completeopt = "menuone,noinsert,noselect,fuzzy,popup,preview"
&completeitemalign = "kind,abbr,menu"
&showbreak = "↪ "
&fillchars = 'eob: '
&signcolumn = "yes"

var stateDir = path.OsStateDir()
&backupdir = stateDir .. '//'
&undodir   = stateDir .. '//'

g:mapleader = " "
g:netrw_dirhistmax = 0

if getcwd() .. '/' == $MYVIMDIR
	g:cgrep_prune_dirs = ["pack"]
endif

if has('gui_running')
    :set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50
else
    &t_SI = "\e[6 q"
    &t_EI = "\e[2 q"
    &t_SR = "\e[4 q"
endif

if exists("+comments")
    :packadd comment
endif

:packadd cfilter
