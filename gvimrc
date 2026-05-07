vim9script

import 'vim.vim'

&guicursor = vim.Option([
	'n-v-c:block',
	'i-ci:ver25',
	'r-cr:hor20',
	'o:hor50'
])

&guifont = 'CodeNewRoman Nerd Font Mono 15'
&guifontwide = 'CodeNewRoman Nerd Font Mono 15'
set guioptions-=T
set linespace=-2
