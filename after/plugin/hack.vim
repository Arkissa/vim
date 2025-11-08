vim9script

import 'command.vim'

type Command = command.Command

Command.new('Copen')
	.Bang()
	.Bar()
	.Overlay()
	.Command("dispatch#copen(<bang>0, '<mods>' ?? 'belowright')")
