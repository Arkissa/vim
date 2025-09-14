vim9script

if !exists("g:Grep")
	import '../autoload/plugin/greps/grepprg.vim'
	g:Grep = grepprg.Grepprg.new()
endif

import '../autoload/command.vim'

type Command = command.Command
type NArgs = command.NArgs

var typeCheck: command.Execute = g:Grep

Command.new("Grep")
	.Bar()
	.Bang()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		var grep: command.Execute = g:Grep

		if has_key(b:, "Grep")
			grep = b:Grep
		endif

		grep.Attr(attr).Run()
	})
