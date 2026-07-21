vim9script

if exists('b:current_syntax')
	finish
endif

syn match qfLine "^\(\\ \|[^ \t]\)\+:\d\+\(-\d\+\)\{0,1\}:\(\d\+-\d\+:\)\{0,1\}.*" transparent contains=qfFileName

syn match qfFileName "^\(\\ \|[^ \t]\)\+" contained nextgroup=qfLineCol skipwhite
syn match qfLineCol ":\d\+\(-\d\+\)\{0,1\}:\(\d\+-\d\+:\)\{0,1\}" contained nextgroup=qfText skipwhite
syn match qfText ".*" contained

&l:conceallevel = 2
&l:concealcursor = 'nvc'

hlset([
	# {name: 'qfError', default: true, linksto: 'ErrorMsg'},
	# {name: 'qfWarn', default: true, linksto: 'WarningMsg'},
	# {name: 'qfInfo', default: true, guifg='#94E2D5'},
	# {name: 'qfNote', default: true, guifg='#94E2D5'},
	{name: 'qfFileName', default: true, guifg='#89B4FA'},
	{name: 'qfLineCol', default: true, linksto: 'Number'},
])

b:current_syntax = 'qf'
