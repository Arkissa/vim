vim9script

if !exists("g:Grep")
	import autoload 'greps/grepprg.vim'
	g:Grep = grepprg.Grepprg.new()
endif

import autoload 'command.vim'

var typeCheck: command.Execute = g:Grep

command.Command.new("Grep")
	.Bang()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		g:Grep.Attr(attr).Run()
	})
