vim9script

import 'command.vim'
import 'quickfix.vim'

type Command = command.Command
type Quickfix = quickfix.Quickfix

Command.new('Copen')
	.Bang()
	.Bar()
	.Overlay()
	.Callback((attr) => {
		dispatch#copen(attr.bang, '<mods>' ?? 'belowright')
		Quickfix.newCurrent().Window()
	})
