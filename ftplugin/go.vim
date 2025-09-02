vim9script

import autoload 'vim.vim'

g:go_highlight_types = 1
g:go_highlight_fields = 1
g:go_highlight_functions = 1
g:go_highlight_function_calls = 1
g:go_highlight_operators = 1
g:go_highlight_extra_types = 1
g:go_highlight_build_constraints = 1
g:go_highlight_generate_tags = 1

b:linter = vim.Cmd(
	'golangci-lint',
	'run'
)

b:linterformat = [
	'%-G',
	'%E%f:%l:%c:\ Error%m',
	'%-G%\d%\+\ issues:',
	'%-G*\ %\k%\+: %\d%\+',
]
b:grepargs = ["--prune-dir=proto"]

:command! -bang -buffer -nargs=* Go Dispatch<bang> go <args>
:setlocal nobuflisted
:setlocal nolist
:setlocal nowrap
