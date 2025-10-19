vim9script noclear

if exists('b:did_ftplugin')
	finish
endif

b:did_ftplugin = 1
b:undo_ftplugin = 'setlocal foldmethod< autocomplete< complete<'

import 'vim.vim'

&l:foldmethod = 'marker'

&l:autocomplete = true
&l:complete = 'o'
