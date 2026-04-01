vim9script

import 'vim.vim'

&l:makeprg = 'cabal'
&l:errorformat = vim.Option([
	'%W%f:(%l\,%c)-(%e\,%k): %tarning: %m',
	'%W%f:(%l\,%c)-(%e\,%k): %tarning:',
	'%W%f:%l:%c-%k:\ %tarning:%m',
	'%W%f:%l:%c-%k:\ %tarning:',
	'%W%f:%l:%c: %tarning:%m',
	'%W%f:%l:%c: %tarning:',
	'%E%f:(%l\,%c)-(%e\,%k): %trror: %m',
	'%E%f:(%l\,%c)-(%e\,%k): %trror:',
	'%E%f:%l:%c-%k: %trror: %m',
	'%E%f:%l:%c-%k: %trror:',
	'%E%f:%l:%c: %trror: %m',
	'%E%f:%l:%c: %trror:',
	'%-G[%.%#] Compiling %m'
])
