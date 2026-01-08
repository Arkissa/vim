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
			module: 'greps/cgrep',
			ft: ['go', 'gomod', 'json', 'lua', 'rs', 'yaml', 'c', 'java', 'cpp', 'haskell', 'python', 'js', 'ts', 'bash', 'cabal'],
			keymaps: {
				['\w']: ':Grep ',
				['\s']: ":Grep --string \\\"\\\"<Left><Left>",
				['\r']: ':Grep -G ',
				['\d']: ':Grep --name -w <C-r><C-w>',
			},
			args: {
				prune_dirs: ["proto", "3rd", "bin", "node_modules", "dist-newstyle", ".git"],
				kind: ["Language"]
			}
		},
		{
			module: 'greps/gnugrep',
			keymaps: {
				['\w']: ':Grep ',
			},
			args: {
				exclude_dir: ["proto", "3rd", "bin", "node_modules", "dist-newstyle", ".git"],
			}
		},
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
