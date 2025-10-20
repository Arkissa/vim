vim9script

if exists('b:did_ftplugin')
	finish
endif

b:did_ftplugin = 1
b:undo_ftplugin = 'setlocal formatexpr<'

import autoload 'dist/json.vim'

&l:formatexpr = 'json.FormatExpr()'
