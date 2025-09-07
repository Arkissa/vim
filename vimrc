vim9script

import autoload 'greps/cgrep.vim'
import autoload 'linters/golangci.vim'
import autoload 'vim.vim'
import autoload 'path.vim'

if has('gui_running')
    :set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50
else
    &t_SI = "\e[6 q"
    &t_EI = "\e[2 q"
    &t_SR = "\e[4 q"
endif

if exists('+comments')
    :packadd comment
endif

:packadd cfilter
:packadd nohlsearch
:packadd hlyank
:packadd helptoc

if has('win')
	:set winaltkeys
endif

:set nocompatible
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
:set lazyredraw
:set shortmess+=c
:set spelllang+=cjk
:set dir-=.

:colorscheme catppuccin
:filetype plugin indent on
:syntax on

var stateDir = path.OsStateDir()
&backupdir = stateDir .. '//'
&undodir   = stateDir .. '//'
&ttimeoutlen = 50
&scrolloff = 99
&pumheight = 15
&shiftwidth = 4
&softtabstop = 4
&tabstop = 4
&laststatus = 2
&updatetime = 300
&completeslash = 'slash'
&showbreak = '↪ '
&fillchars = 'eob: '
&signcolumn = 'yes'
&autocomplete = true
&display = 'lastline'
&completeopt = vim.Option(['menuone', 'noinsert', 'noselect', 'fuzzy', 'popup', 'preview'])
&completeitemalign = vim.Option(['kind', 'abbr', 'menu'])
&complete = vim.Option(['o', 't', 'F', '.', 'w', 'u'])
&suffixes = vim.Option(['.bak', '~', '.o', '.h', '.info', '.swp', '.obj', '.pyc', '.pyo', '.egg-info', '.class'])
&wildignore = vim.Option([
	'*.o', '*.obj', '*~', '*.exe', '*.a', '*.pdb', '*.lib',
	'*.so', '*.dll', '*.swp', '*.egg', '*.jar', '*.class',
	'*.pyc', '*.pyo', '*.bin', '*.dex', '*.zip', '*.7z',
	'*.rar', '*.gz', '*.tar', '*.gzip', '*.bz2', '*.tgz', '*.xz',
 	'*DS_Store*', '*.ipch', '*.gem', '*.png', '*.jpg', '*.gif',
	'*.bmp', '*.tga', '*.pcx', '*.ppm', '*.img', '*.iso', '*.so',
	'*.swp', '*.zip', '*/.Trash/**', '*.pdf', '*.dmg', '*/.rbenv/**',
 	'*/.nx/**', '*.app', '*.git', '.git/', '__pycache__/', 'dist-newstyle/',
 	'*.wav', '*.mp3', '*.ogg', '*.pcm', 'node_modules/', '*.pb.*'
])

if $MYVIMDIR =~# $'^{getcwd()}'
	&wildignore ..= ',pack/'
endif

g:mapleader = ' '
g:netrw_dirhistmax = 0

g:Linters = {
	go: {
		lint: golangci.GolangCiLint.new(),
		onSaveCmd: "silent LLint %"
	}
}

&grepprg = vim.Cmd(['grep', '-r', '-n', '$*'])

g:Grep = cgrep.Cgrep.new({
	types: ["Go"],
	pruneDirs: ["proto"],
	kind: ["Language"]
})
