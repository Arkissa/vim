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

const group = 'REPLDebug'
const REPLDebugUI = repldebug.REPLDebugUI

var REPLDebugConfig: dict<any> = g:REPLDebugConfig

const modules = REPLDebugConfig.modules

def REPLDebug(expr: string, exprAttach: string)
	Command.new('REPLDebug')
		.Bar()
		.Buffer()
		.Overlay()
		.NArgs(NArgs.Star)
		.Callback((attr) => {
			REPLDebugUI.Open(eval(printf(expr, attr.args)))
		})

	Command.new('REPLDebugAttach')
		.Bar()
		.Buffer()
		.Overlay()
		.NArgs(NArgs.One)
		.Callback((attr) => {
			REPLDebugUI.Open(eval(printf(exprAttach, attr.args)))
		})

	Command.new('REPLDebugClose')
		.Bar()
		.Buffer()
		.Overlay()
		.Callback(() => {
			REPLDebugUI.Close()
		})

	Command.new('REPLDebugSessionPrev')
		.Bar()
		.Buffer()
		.Overlay()
		.Callback(REPLDebugUI.Prev)

	Command.new('REPLDebugSessionNext')
		.Bar()
		.Buffer()
		.Overlay()
		.Callback(REPLDebugUI.Next)

	Command.new('ToggleBreakpoint')
		.Bar()
		.Buffer()
		.Overlay()
		.Callback(REPLDebugUI.ToggleBreakpoint)
enddef

for module in modules
	var [ft, name] = module
	import autoload $'{name}.vim'

	var m = fnamemodify(name, ':t:r')
	Autocmd.new('FileType')
		.Group(group)
		.Pattern([ft])
		.Callback(function(REPLDebug, [$'{m}.Backend.new("%s")', $'{m}.Backend.newAttach("%s")']))
endfor
