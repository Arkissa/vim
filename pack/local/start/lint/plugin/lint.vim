vim9script

import 'command.vim'
import 'autocmd.vim'

type Command = command.Command
type Autocmd = autocmd.Autocmd

const group = "Linter"

if exists('g:lint_auto_open_qf')
	var au = Autocmd.new('QuickFixCmdPost')
		.Group(group)
		.Pattern(['Lint', 'LLint'])

	au.Callback((attr) => {
		attr.qf.Window()
	})
endif

Command.new("Lint")
	.Bar()
	.Bang()
	.Overlay()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		var lint: command.ErrorFormat = get(b:, 'lintprg', get(g:, 'lintprg', null_object))
		if lint == null_object
			echoerr 'No defined lintprg.'
			return
		endif

		lint.Attr(attr).Run()
	})

Command.new("LLint")
	.Bar()
	.Bang()
	.Overlay()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		var lint: command.ErrorFormat = get(b:, 'lintprg', get(g:, 'lintprg', null_object))
		if lint == null_object
			echoerr 'No defined lintprg.'
			return
		endif

		lint.Attr(attr, true).Run()
	})
