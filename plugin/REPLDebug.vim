vim9script

if !exists("g:REPLDebugConfig")
	finish
endif

import 'command.vim'
import 'autocmd.vim'
import '../autoload/REPLDebug/REPLDebug.vim'

type NArgs = command.NArgs
type Autocmd = autocmd.Autocmd
type Command = command.Command
type Complete = command.Complete
type UI = REPLDebug.REPLDebugUI

const group = 'REPLDebug'
final REPLDebugUI = UI.new()

var REPLDebugConfig: dict<any> = g:REPLDebugConfig

const modules = REPLDebugConfig.modules

# handle ! on args of start.
def Shell(args: string): string
	if args !~ '^!'
		return args
	endif

	var out = systemlist(args[1 : ])
	if len(out) < 1
		return args
	endif

	return trim(out[0])
enddef

def Debug(expr: string, exprAttach: string)
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
			REPLDebugUI.Open(eval(printf(exprAttach, Shell(attr.args))))
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
		.Callback(function(Debug, [$'{m}.Backend.new("%s")', $'{m}.Backend.newAttach("%s")']))
endfor
