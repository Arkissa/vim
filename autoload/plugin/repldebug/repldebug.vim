vim9script

import autoload 'vim.vim'
import autoload 'job.vim' as jb
import autoload 'window.vim'
import autoload 'terminal.vim'

type Ring = vim.Ring
type Coroutine = vim.Coroutine

export class Variable
	var Type: string
	var Name: string
	var Value: string

	def new(this.Type, this.Name, this.Value)
	enddef
endclass

export enum VariableTag
	Watch,
	Global,
	Local
endenum

class DebugVariables
	var _win: window.Window
	var _variables: dict<dict<Variable>> = {
		Watch: {},
		Global: {},
		Local: {},
	}

	def new()
		this._win = window.Window.new('REPLDebug-Variables')
		this._win.OnSetBufPost((_) => {
			g:asyncio.Run(Coroutine.new(this.Draw))
		})
	enddef

	def SetBuffer(buf: buffer.Buffer)
		this._win.SetBuffer(buf)
	enddef

	def Fill(tag: VariableTag, d: dict<Variable>)
		this._variables[tag.name] = d
	enddef

	def Update(tag: VariableTag, d: dict<Variable>)
		var vars = this._variables[tag.name]
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
				thn[2] = vl
			endif
		endfor

		return tnl->list2tuple()
	enddef

	static def _Banner(d: dict<Variable>): list<string>
		var [tl, nl, vl] = _MaxLength(d)

		var format = $'%{tl}s %{nl}s %{vl}s'
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

		buf.Clear()
		buf.SetLine(lines)
	enddef
endclass

export class Address
	var FileName: string
	var Lnum: string
	var Col: string
endclass

class DebugCodeWindow
	const signGroup = 'REPLDebug'
	var _win: window.Window
	var _breakpoints: dict<dict<Address>>

	def new()
		this._win.SetBuffer(original)
	enddef

	def SetBuffer(buf: buffer.Buffer)
		this._win.SetBuffer(buf)
	enddef

	def SetBreakpoint(sessionId: number, breakId: number, addr: Address)
		var signName = $'{sessionId}-{breakId}'
		sign_define(signName, {
			text: '*',
			texthl: 'red',
		})

		this._breakpoints[sessionId][breakId] = addr
		sign_place(breakId, $'{signGroup}-{sessionId}', signName, this._win.GetBufnr(), {lnum: addr.lnum, priority: 110})
	enddef

	def DeleteBreakpoint(sessionId: number, breakId: number, addr: Address)
		sign_unplace(signGroup, {buffer: this._win.GetBufnr(), id: breakId})
		remove(this._breakpoints[sessionId], breakId)
	enddef

	def BreakpointToggle(sessionId: number, breakId: number, addr: Address)
		if !has_key(this._breakpoints, sessionId) || !has_key(this._breakpoints[sessionId], breakId)
			this.SetBreakpoint(sessionId: number, breakId: number, addr: Address)
		else
			this.DeleteBreakpoint(sessionId: number, breakId: number, addr: Address)
		endif
	enddef

	def Goto(addr: Address)
		var buf = this._win.GetBuffer()
		if buf.name != fname
			buf = buffer.Buffer.new(addr.FileName)
		endif

		this._win.SetBuffer(buf)
		this._win.SetCursor(addr.Lnum, addr.Col)
	enddef

	def DeleteSession(sessionId: number, addr: Address)
		if has_key(this._breakpoints, sessionId)
			var d = remove(this._breakpoints, sessionId)
			d->keys()->foreach((_, breakId) => {
				sign_undefine($'{sessionId}-{breakId}')
			})
			sign_unplace($'{signGroup}-{sessionId}')
		endif
	enddef
endclass

class DebugStackWindow
	var _win: window.Window

	def new()
		this._win = window.Window.new('REPLDebug-Stack')
	enddef

	def Draw()
	enddef
endclass

class DebugDisassembler
	var _win: window.Window

	def Draw()
	enddef
endclass

export class REPLDebugUI
	var _code: DebugCodeWindow
	var _stack: DebugCodeWindow
	var _prompt: DebugStackWindow
	var _variables: DebugVariablesWindow
	var _disassembler: DebugDisassembler

	def SetBreakpoint()
	enddef
endclass

export class REPLDebugManager
	var _Session: Ring
	var _UI: REPLDebugUI

	def new()
	enddef

	def OpenVariablesWindow(): DebugVariables
		return _Variables ?? DebugVariables.new()
	enddef

	def NextSession()
		this._Session.SlideRight()
	enddef

	def PrevSession()
		this._Session.SlideLeft()
	enddef

	def BreakpointToggle()
		var cur = _Session.Current()
		cur.BreakpointToggle()
	enddef

	def Set(repl: REPLDebug)
		if _VariablesWindow != null_object
			_VariablesWindow.SetBuffer(repl.VariablesBuffer)
		endif

		if _StackWindow != null_object
			_StackWindow.SetBuffer(repl.StackBuffer)
		endif

		_PromptWindow.SetBuffer(repl.prompt)
		_CodeWindow.SetBuffer(repl.CodeBuffer)
		_Pty.SetBuffer(repl.Pty)
	enddef
endclass

export abstract class REPLDebugBackend extends jb.Prompt
	var UI: REPLDebugUI

	abstract def Callback(channel, string) # {{{2
	abstract def Prompt(): string # {{{2
	abstract def BreakpointToggle(Breakpoint) # {{{2

	def Run()
		this.CodeBuffer = buffer.Buffer.newCurrent()
		super.Run()
		this.Pty = terminal.Terminal.new('NONE', {
			pty: true,
		})
	enddef
endclass
