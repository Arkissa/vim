vim9script

if executable('golangci-lint') != 1
	finish
endif

import 'command.vim'
import 'autocmd.vim'
import autoload 'lint/golangci.vim'

type Command = command.Command
type Autocmd = autocmd.Autocmd

const group = "Linter"

Autocmd.new('FileType')
	.Group(group)
	.Pattern(['go'])
	.Callback(() => {
		b:lintprg = golangci.Lint.new()
	})
