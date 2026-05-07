vim9script

import 'vim.vim'

g:mapleader = ' '
g:netrw_keepj = 'keepj'
g:netrw_dirhistmax = 0
g:dispatch_no_maps = 1
g:myvimrc_group = 'MYVIMRC'

g:quickfix_previewer_config = {
	highlight: "Cursor",
	number: true,
	cursorline: true,
	padding: [0, 0, 0, 0],
	border: [1, 1, 1, 1],
	borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
	borderhighlight: ["Title", "Title", "Title", "Title"],
}

g:lint_auto_open_qf = true
g:grep_auto_open_qf = true
g:session_auto_save = true

g:helptoc = {
	shell_prompt: '^\$\s'
}

:set exrc
