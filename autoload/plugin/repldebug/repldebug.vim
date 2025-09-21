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

class DebugVariablesWindow extends window.Window
	var _variables: dict<dict<Variable>> = {
		Watch: {},
		Global: {},
		Local: {},
	}

	def new()
		this.OnSetBufPost((_) => {
			g:asyncio.Run(this.Draw())
		})
	enddef

	def Update(tag: VariableTag, vs: dict<Variable>)
		var vars = this._variables[tag.name]
		for [k, v] in vs.items()
			vars[v.Name] = v
		endfor

		g:asyncio.Run(this.Draw())
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

	def Draw(): Coroutine
		return Coroutine.new(() => {
			var lines = []

			for [tag, vars] in items(this._variables)
				lines->add($'{tag} Variables:')
				lines->extend(_Banner(vars))
			endfor

			buf.Clear()
			buf.SetLine(lines)
		})
	enddef
endclass

export class Address
	var FileName: string
	var Lnum: string
	var Col: string

	def new(this.FileName, this.Lnum)
	enddef

	def newAll(this.FileName, this.Lnum, this.Col)
	enddef

	def string(): string
		return this.Col == null_string ? $'{this.FileName}:{this.Lnum}' : $'{this.FileName}:{this.Lnum}:{this.Col}'
	enddef
endclass

class DebugCodeWindow extends window.Window
	const signGroup = 'REPLDebug'
	var _win: window.Window
	var _breakpoints: dict<dict<Address>>

	def GetBreakpoints(sessionID: number): dict<Address>
		return this._breakpoints[sessionID]
	enddef

	def SetBreakpoint(sessionID: number, breakID: number, addr: Address)
		var signName = $'{sessionId}-{breakID}'
		sign_define(signName, {
			text: '*',
			texthl: 'red',
		})

		this._breakpoints[sessionID][breakID] = addr
		sign_place(breakId, $'{signGroup}-{sessionID}', signName, this._win.GetBufnr(), {lnum: addr.lnum, priority: 110})
	enddef

	def DeleteBreakpoint(sessionID: number, breakID: number, addr: Address)
		sign_unplace(signGroup, {buffer: this._win.GetBufnr(), id: breakID})
		remove(this._breakpoints[sessionID], breakID)
	enddef

	def BreakpointToggle(sessionID: number, breakID: number, addr: Address)
		if !has_key(this._breakpoints, sessionID) || !has_key(this._breakpoints[sessionID], breakID)
			this.SetBreakpoint(sessionID: number, breakID: number, addr: Address)
		else
			this.DeleteBreakpoint(sessionID: number, breakID: number, addr: Address)
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

	def DeleteSession(sessionId: number)
		if has_key(this._breakpoints, sessionId)
			var d = remove(this._breakpoints, sessionId)
			d->keys()->foreach((_, breakId) => {
				sign_undefine($'{sessionId}-{breakId}')
			})
			sign_unplace($'{signGroup}-{sessionId}')
		endif
	enddef
endclass

export class REPLDebugUI
	var prompt: window.Window
	var code: DebugCodeWindow
	final _extends: dict<window.Window>

	def new(prompt: buffer.Buffer)
		this.code = DebugCodeWindow.newCurrent()
		this.prompt = window.Window.newByBuffer(prompt)
	enddef

	def ExtendsWindow(name: string, win: window.Window)
		this._extends[name] = win
	enddef

	def GetExtendsWindow(name: string): window.Window
		return has_key(this._extends, name) ? this._extends[name] : null_object
	enddef

	def Close()
		this.prompt.Close()
		for win in values(this._extends)
			win.Close()
		endfor
		this.code = null_object
	enddef
endclass

export class REPLDebugManager
	var _UI: REPLDebugUI
	var _Session: Ring

	def Open(repl: REPLDebugBackend)
		this._UI = this._UI ?? REPLDebugUI.new(repl.prompt)
		repl.OnInterruptCb(this._OnInterruptCb)
		repl.SetUI(this._UI)

		if this._Session == null_object
			this._Session = Ring.new(repl)
		else
			this._Session.Add(repl)
		endif
	enddef

	def _OnInterruptCb()
		this._UI.code.DeleteSession(this._Session.Current().id)
		this.NextSession()
	enddef

	def NextSession()
		this._Session.SlideRight()
	enddef

	def PrevSession()
		this._Session.SlideLeft()
	enddef

	def ToggleBreakpoint()
		var cur = this._Session.Current()
		var buf = this._UI.code.GetBuffer()
		var [lnum, col] = this._UI.code.GetCursorPos()
		var cmd = cur.HandleToggleBreakpointCmd($'{buf.name}:{lnum}:{col}')
		if cmd != ""
			cur.Send(cmd)
		endif
	enddef

	def Close()
		this._Session.ForEach((repl: REPLDebugBackend) => {
			repl.Delete()
		})
	enddef
endclass

final debug = vim.IncID.new()

export abstract class REPLDebugBackend extends jb.Prompt
	var id = debug.ID()
	var _UI: REPLDebugUI
	var _OnInterruptCb: func()

	abstract def Bufname(): string # {{{2
	abstract def Prompt(): string # {{{2
	abstract def HandleToggleBreakpointCmd(text: string): string # {{{2
	abstract def HandleGotoCmd(text: string): Address

	def Callback(_: channel, line: string) # {{{2
		var cmd = this.HandleToggleBreakpointCmd(line)
		if cmd != ""
			this.Send(cmd)
			return
		endif

		var addr = this.HandleGotoCmd(line)
		if addr != null_object
			this._UI.code.Goto(addr)
			return
		endif

		this.prompt.AppendLine(line)
	enddef # }}}

	def OnInterrupt(F: func()) # {{{2
		this._OnInterruptCb = F
	enddef # }}}

	def InterruptCb() # {{{2
		this._OnInterruptCb()
		super.InterruptCb()
	enddef # }}}

	def SetUI(ui: REPLDebugUI) # {{{2
		this._UI = ui
		this._UI.prompt.SetBuffer(this.prompt)
	enddef # }}}
endclass
