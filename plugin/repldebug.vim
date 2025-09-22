vim9script

if !exists("g:REPLDebugConfig")
	finish
endif

import '../autoload/command.vim'
import '../autoload/autocmd.vim'
import '../autoload/plugin/repldebug/repldebug.vim'

type NArgs = command.NArgs
type Command = command.Command
type Complete = command.Complete
type Autocmd = autocmd.Autocmd
type REPLDebugManager = repldebug.REPLDebugManager

const group = 'REPLDebug'

var manager = REPLDebugManager.new()
var REPLDebugConfig: dict<string> = g:REPLDebugConfig

for [ft, module] in REPLDebugConfig->items()
	import autoload $'{module}.vim' as REPL

	var REPLDebug = () => {
		Command.new('REPLDebug')
			.Bar()
			.Buffer()
			.Overlay()
			.NArgs(NArgs.Star)
			.Callback((attr) => {
				manager.Open(eval($'REPL.Backend.new("{attr.args}")'))
			})

		Command.new('REPLDebugAttach')
			.Bar()
			.Buffer()
			.Overlay()
			.NArgs(NArgs.One)
			.Callback((attr) => {
				manager.Open(eval($'REPL.Backend.newAttach("{attr.args}")'))
			})

		Command.new('REPLDebugClose')
			.Bar()
			.Buffer()
			.Overlay()
			.Callback(() => {
				manager.Close()
				manager = REPLDebugManager.new()
			})

		Command.new('REPLDebugSessionPrev')
			.Bar()
			.Buffer()
			.Overlay()
			.Callback(manager.PrevSession)

		Command.new('REPLDebugSessionNext')
			.Bar()
			.Buffer()
			.Overlay()
			.Callback(manager.NextSession)

		Command.new('ToggleBreakpoint')
			.Bar()
			.Buffer()
			.Overlay()
			.Callback(manager.ToggleBreakpoint)
	}

	Autocmd.new('FileType')
		.Group(group)
		.Pattern([ft])
		.Callback(REPLDebug)
endfor
