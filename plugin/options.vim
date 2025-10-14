vim9script

import 'vim.vim'

if has('gui_running')
    :set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50
else
    &t_SI = "\e[6 q"
    &t_EI = "\e[2 q"
    &t_SR = "\e[4 q"
endif

:packadd hlyank
:packadd helptoc
:packadd matchit
:packadd cfilter
:packadd comment
:packadd nohlsearch

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
:set ruler
:set hlsearch
:set lazyredraw
:set shortmess+=c
:set spelllang+=cjk
:set dir-=.

&ttimeoutlen = 50
&scrolloff = 99
&pumheight = 15
&shiftwidth = 4
&softtabstop = 4
&tabstop = 4
&laststatus = 2
&updatetime = 300
&wildoptions = 'pum'
&wildmode = 'noselect:lastused,full'
&completeslash = 'slash'
&showbreak = '↪ '
&fillchars = 'eob: '
&signcolumn = 'yes'
&display = 'lastline'
&sessionoptions = vim.Option([
	'buffers', 'tabpages', 'winsize',
	'winpos', 'resize', 'terminal', 'folds', 'help',
	'localoptions'
])
&completeopt = vim.Option(['menuone', 'noinsert', 'noselect', 'fuzzy', 'popup', 'preview', 'longest'])
&completefuzzycollect = vim.Option(['keyword', 'files', 'whole_line'])
&completeitemalign = vim.Option(['kind', 'abbr', 'menu'])
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
 	'*.wav', '*.mp3', '*.ogg', '*.pcm', 'node_modules/', '*.pb.*', '*/3rd/**'
])

if $MYVIMDIR =~# $'^{getcwd()}'
	&wildignore ..= ',pack/'
endif
