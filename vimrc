vim9script

import 'vim.vim'
import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

g:mapleader = ' '
g:netrw_keepj = 'keepj'
g:netrw_dirhistmax = 0
g:dispatch_no_maps = 1

g:REPLDebugConfig = {
	modules: [
		('go', 'REPLDebug/delve'),
	],
	step: {
		icon: '=>',
		linehl: 'CursorLine',
	},
	breakpoint: {
		icon: '●'
	},
	prompt_window: {
		pos: 'horizontal botright',
		height: 20,
	}
}

g:GrepConfig = [
	{
		module: 'greps/grepprg',
		Init: () => {
			&grepprg = vim.Cmd(['grep', '-r', '-n', '$*'])
		},
		keymaps: {
			bind: Bind.new(Mods.n).Buffer().NoRemap(),
			['\w']: ':Grep ',
		}
	},
	{
		module: 'greps/cgrep',
		ft: 'go',
		keymaps: {
			bind: Bind.new(Mods.n).Buffer().NoRemap(),
			['\w']: ':Grep ',
			['\s']: ':Grep --string ',
			['\r']: ':Grep -G ',
			['\d']: ':Grep --name <C-r><C-w>',
		},
		args: {
			types: ["Go"],
			pruneDirs: ["proto", "3rd", "bin", "node_modules", "dist-newstyle", ".git"],
			kind: ["Language"]
		}
	}
]

g:LinterConfig = {
	go: {
		module: 'linters/golangci',
		# onSaveCmd: 'silent LLint %:p:h'
	}
}

g:SimpleSession = {
	saveOnVimLeave: true
}

g:helptoc = {
	shell_prompt: '^\$\s'
}

:colorscheme catppuccin
:filetype plugin indent on
:syntax on
