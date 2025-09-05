vim9script

if !exists("g:Grep")
	g:Grep = Grepprg.new()
endif

import autoload 'command.vim'

var typeCheck: command.Execute = g:Grep

command.Command.new("Grep")
	.Bang()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		var grep: command.Execute = g:Grep
		grep.Attr(attr).Run()
	})
