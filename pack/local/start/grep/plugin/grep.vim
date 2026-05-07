vim9script

import 'command.vim'
import 'autocmd.vim'
import autoload 'grep/grepprg.vim'
import autoload 'grep/gnugrep.vim'

type Command = command.Command
type Autocmd = autocmd.Autocmd

const group = 'grep'

if exists('g:grep_auto_open_qf')
	var at = Autocmd.new('QuickFixCmdPost')
		.Group(group)
		.Desc('when Grep command result post will be open quickfix or loclist window.')
		.Pattern(['Grep'])

	at.Callback((attr) => {
		var qf = attr.data
		if !qf.IsEmpty()
			qf.Open()
		endif
	})
endif

Command.new("Grep")
	.Bar()
	.Bang()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		const grep: grepprg.Grepprg  = get(b:, 'grepprg', get(g:, 'grepprg', null_object))
		if grep == null_object
			echoerr 'No defined Grep.'
			return
		endif

		grep.Attr(attr).Run()
	})

g:grepprg = gnugrep.Grep.new()
