vim9script

import 'keymap.vim'
import 'autocmd.vim'
import autoload 'grep/cgrep.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Autocmd = autocmd.Autocmd

var ft = [
	'go',
	'gomod',
	'markdown',
	'json',
	'lua',
	'rust',
	'yaml',
	'c',
	'java',
	'cpp',
	'haskell',
	'python',
	'javascript',
	'typescript',
	'bash',
	'cabal',
]

Autocmd.new('FileType')
	.Group('group')
	.Desc('cgrep')
	.Pattern(ft)
	.Callback(() => {
		b:grepprg = cgrep.Grep.new()
		Bind.new(Mods.n)
			.Buffer(bufnr())
			.Map('\w', ':Grep ')
			.Map('\s', ":Grep --string \\\"\\\"<Left><Left>")
			.Map('\r', ':Grep -G')
			.Map('\d', ':Grep --name -w <C-r><C-w>')
	})
