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
		var qf = Quickfix.newCurrent()
		if !qf.IsEmpty()
			qf.Open()
		endif
	})
