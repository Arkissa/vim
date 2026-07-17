vim9script

import 'vim.vim'

&guicursor = vim.Option([
	'n-v-c:block',
	'i-ci:ver25',
	'r-cr:hor20',
	'o:hor50',
	'a:blinkon0'
])


&guifont = 'Maple Mono NF 12'
&guifontwide = 'Maple Mono NF 12'

:set guioptions-=T
:set guioptions-=m
:set guioptions-=l
:set guioptions-=L
:set winaltkeys=no
