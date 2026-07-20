vim9script

import 'vim.vim'

:set guioptions-=T
:set guioptions-=m
:set guioptions-=l
:set guioptions-=L
:set winaltkeys=no

&guifont = 'Maple Mono NL NF CN 11'
&guifontwide = 'Maple Mono NL NF CN 11'
&guicursor = vim.Option([
	'n-v-c:block',
	'i-ci:ver25',
	'r-cr:hor20',
	'o:hor50',
	'a:blinkon0'
])
