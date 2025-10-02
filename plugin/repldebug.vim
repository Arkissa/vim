vim9script

if !exists("g:REPLDebugConfig")
	finish
endif

import 'command.vim'
import 'autocmd.vim'
import '../autoload/repldebug/repldebug.vim'

type NArgs = command.NArgs
type Autocmd = autocmd.Autocmd
type Command = command.Command
type Complete = command.Complete

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
		.Complete(Complete.ShellCmd)
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

	Command.new('REPLDebugPrev')
		.Bar()
		.Buffer()
		.Overlay()
		.Callback(REPLDebugUI.Prev)

	Command.new('REPLDebugNext')
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
