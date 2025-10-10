vim9script

import 'vim.vim'
import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

g:mapleader = ' '
g:netrw_keepj = 'keepj'
g:netrw_dirhistmax = 0
g:dispatch_no_maps = 1

g:REPLDebugConfig = {
	modules: [
		('go', 'REPLDebug/delve'),
	],
	step: {
		icon: '=>',
		linehl: 'CursorLine',
	},
	breakpoint: {
		icon: '●'
	},
	prompt_window: {
		pos: 'horizontal botright',
		height: 20,
	}
}

g:GrepConfig = [
	{
		module: 'greps/grepprg',
		Init: () => {
			&grepprg = vim.Cmd(['grep', '-r', '-n', '$*'])
		},
		keymaps: {
			bind: Bind.new(Mods.n).Buffer().NoRemap(),
			['\w']: ':Grep ',
		}
	},
	{
		module: 'greps/cgrep',
		ft: 'go',
		keymaps: {
			bind: Bind.new(Mods.n).Buffer().NoRemap(),
			['\w']: ':Grep ',
			['\s']: ':Grep --string ',
			['\r']: ':Grep -G ',
			['\d']: ':Grep --name <C-r><C-w>',
		},
		args: {
			types: ["Go"],
			pruneDirs: ["proto", "3rd", "bin", "node_modules", "dist-newstyle", ".git"],
			kind: ["Language"]
		}
	}
]

g:LinterConfig = {
	go: {
		module: 'linters/golangci',
		# onSaveCmd: 'silent LLint %:p:h'
	}
}

g:SimpleSession = {
	saveOnVimLeave: true
}

g:helptoc = {
	shell_prompt: '^\$\s'
}

if has('gui_running')
    :set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50
else
    &t_SI = "\e[6 q"
    &t_EI = "\e[2 q"
    &t_SR = "\e[4 q"
endif

:packadd comment
:packadd cfilter
:packadd nohlsearch
:packadd hlyank
:packadd helptoc
:packadd matchit

if has('win')
	:set winaltkeys
endif

:set nocompatible
:set exrc
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
