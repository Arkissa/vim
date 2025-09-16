vim9script

import autoload 'vim.vim'
import autoload 'job.vim' as jb
import autoload 'window.vim'
import autoload 'terminal.vim'

type Ring = vim.Ring

export class Variable
	var Type: string
	var Name: string
	var Value: string

	def new(this.Type, this.Name, this.Value)
	enddef
endclass

class DebugVariables
	var _win: window.Window
	var _variables: dict<dict<Variable>> = {
		Watch: {},
		Global: {},
		Local: {},
	}

	def new()
		this._win = window.Window.new('REPLDebug-Variables')
	enddef

	def SetWatch(tag: string, d: dict<Variable>)
		this._variables[tag] = d
	enddef

	def Update(tag: string, d: dict<Variable>)
		var vars = this._variables[tag]
		for [k, v] in d->items()
			vars[k] = v
		endfor
	enddef

	static def _MaxLength(d: dict<Variable>): tuple<number, number, number>
		var tnv = [0, 0, 0]
		for v in values(d)
			var tl = v.Type->strdisplaywidth()
			if tl > thn[0]
				thn[0] = tl
			endif

			var nl = v.Name->strdisplaywidth()
			if nl > thn[1]
				thn[1] = nl
			endif

			var vl = v.Value->strdisplaywidth()
			if vl > thn[2]
				thn[2] vl
			endif
		endfor

		return tnl->list2tuple()
	enddef

	static def _Banner(d: dict<Variable>): list<string>
		var [tl, nl, vl] = _MaxLength(d)

		var format = $'%-{tl}s %-{nl}s %-{vl}s'
		var lines = [printf(format, 'Type', 'Name', 'Value')]
		for v in values(d)
			lines->add(printf(format, v.Type, v.Name, v.Value))
		endfor

		return lines
	enddef

	def Draw()
		var lines = []

		for [tag, vars] in items(this._variables)
			lines->add($'{tag} Variables:')
			lines->extend(_Banner(vars))
		endfor

		var buf = this._win.GetBuffer()
		buf.Clear()
		buf.SetLine(lines)
	enddef
endclass

class CodeWindow
	var _win: window.Window

	def new()
		this._win = window.Window.newCurrent()
		var original = this._win.GetBuffer()
		this._win.OnClose(() => {
			this._win.SetBuffer(original)
		})
	enddef

	def Goto(fname: string, address: tuple<number, number>)
		var buf = this._win.GetBuffer()
		if buf.name != fname
			buf = buffer.Buffer.new(fname)
		endif

		this._win.SetBuffer(buf)
		this._win.SetCursor(address[0], address[1])
	enddef
endclass

export abstract class REPLDebug extends jb.Prompt
	static var _Session: Ring
	static var _Breakpints: dict<list<string>>
	static var _OrginBuffer: buffer.Buffer
	static var _Variables: DebugVariables
	static var _CodeWindow: window.Window
	static var _PromptWindow: window.Window
	static var _Pty: window.Window
	static var _Signs: list<string>

	abstract def Callback(chan: channel, msg: string) # {{{2
	abstract def Prompt(): string # {{{2

	def GotoLine()
	enddef

	def OpenVariablesWindow(): DebugVariables
		return	_Variables ?? DebugVariables.new()
	enddef

	def Run()
		_CodeWindow = window.Window.newCurrent()
		_PromptWindow = window.Window.new()
		super.Run()
		_PromptWindow.SetBuffer(this.prompt)
		_Pty = window.Window.newByBufer(terminal.Terminal.new('NONE', {
			pty: true,
		}))
	enddef
endclass
