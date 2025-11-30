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

g:grep_config = {
	greps: [
		{
			module: 'greps/grepprg',
			Init: () => {
				&grepprg = vim.Cmd(['grep', '-r', '-n', '$*'])
			},
			keymaps: {
				['\w']: ':Grep ',
			}
		},
		{
			module: 'greps/cgrep',
			keymaps: {
				['\w']: ':Grep ',
				['\s']: ":Grep --string \\\"\\\"<Left><Left>",
				['\r']: ':Grep -G ',
				['\d']: ':Grep --name -w <C-r><C-w>',
			},
			args: {
				types: [],
				pruneDirs: ["proto", "3rd", "bin", "node_modules", "dist-newstyle", ".git"],
				kind: ["Language"]
			}
		}
	],
	auto_open: true
}

g:linter_config = {
	go: {
		module: 'linters/golangci',
	}
}

g:simple_session = {
	autosave: true
}

g:helptoc = {
	shell_prompt: '^\$\s'
}

:set exrc
