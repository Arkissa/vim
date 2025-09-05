vim9script

import autoload 'greps/cgrep.vim'
import autoload 'linters/golangci.vim'

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
:packadd nohlsearch
:packadd hlyank
:packadd helptoc

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

g:mapleader = " "
g:netrw_dirhistmax = 0

cgrep.SetDefault({
	pruneDirs: [
		'.git',
		'__pycache__',
		'dist-newstyle',
		'node_modules',
	]
})

g:Grep = cgrep.Cgrep.new({
	pruneDirs: ["pack"]
})

g:Linters = {
	go: golangci.GolangCiLint.new()
}
