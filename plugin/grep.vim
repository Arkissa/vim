vim9script

import autoload 'grep.vim'
import autoload 'job.vim'
import autoload 'vim.vim'

:command! -bang -nargs=* Grep grep.Grep.new(!empty(<q-bang>)).Run(<q-args>)

&grepprg = vim.Cmd(
	'cgrep',
	'-r',
	'--prune-dir=.git',
	'--prune-dir=__pycache__',
	'--prune-dir=dist-newstyle',
	'--prune-dir=node_modules',
	(getcwd() .. '/' == $MYVIMDIR ? "--prune-dir=pack" : ""),
	'$*',
)

&grepformat = vim.Option(
	'%-G',
	'%f:%l:%c:%m',
)
