vim9script

import 'vim.vim'

&guicursor = vim.Option([
	'n-v-c:block',
	'i-ci:ver25',
	'r-cr:hor20',
	'o:hor50'
])

&guifont = 'FiraCode Nerd Font Mono 11'
&guifontwide = 'FiraCode Nerd Font Mono 11'
set guioptions-=T
