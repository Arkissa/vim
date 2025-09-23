vim9script

import autoload 'vim.vim'
import autoload 'job.vim' as jb
import autoload 'window.vim'
import autoload 'buffer.vim'

type Ring = vim.Ring
type Coroutine = vim.Coroutine
type Async = vim.Async

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

class DebugVariablesWindow extends Async
	var _win: window.Window
	var _variables: dict<dict<Variable>> = {
		Watch: {},
		Global: {},
		Local: {},
	}

	def new(pos: string, height: number)
		this._win = window.Window.new(pos, height)
		this.OnSetBufPost((_) => {
			this.Await(this.Draw())
		})
	enddef

	def Update(tag: VariableTag, vs: dict<Variable>)
		var vars = this._variables[tag.name]
		for [k, v] in vs->items()
			vars[k] = v
		endfor

		this.Await(this.Draw())
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
	var Lnum: number
	var Col: number

	def new(this.FileName, this.Lnum)
	enddef

	def newAll(this.FileName, this.Lnum, this.Col)
	enddef

	def string(): string
		return this.Col == 0
			? $'{this.FileName}:{this.Lnum}'
			: $'{this.FileName}:{this.Lnum}:{this.Col}'
	enddef
endclass

class DebugCodeWindow
	const signGroup = 'REPLDebug'
	const signBreakpoint = 'REPLDebug-Breakpoint'
	var _win: window.Window
	var _breakpoints: dict<dict<tuple<number, Address>>>

	def new()
		this._win = window.Window.newCurrent()
		this._breakpoints = {}
		sign_define(this.signBreakpoint, {
			text: '●',
			texthl: 'REPLDebugBreakpoint',
		})
	enddef

	def GetBreakpoints(sessionID: number): dict<tuple<number, Address>>
		return has_key(this._breakpoints, sessionID) ? this._breakpoints[sessionID] : null_dict
	enddef

	def SetBreakpoint(sessionID: number, addr: Address)
		var signID = sign_place(
			0,
			$'{this.signGroup}-{sessionID}',
			this.signBreakpoint,
			this._win.GetBufnr(),
			{lnum: addr.Lnum, priority: 110}
		)
		if !has_key(this._breakpoints, sessionID)
			this._breakpoints[sessionID] = {}
		endif

		this._breakpoints[sessionID][addr->string()] = (signID, addr)
	enddef

	def ClearBreakpoint(sessionID: number, addr: Address)
		var [signID, _] = remove(this._breakpoints[sessionID], addr->string())
		sign_unplace($'{this.signGroup}-{sessionID}', {buffer: this._win.GetBufnr(), id: signID})
	enddef

	def ToggleBreakpoint(sessionID: number, addr: Address)
		if !this.BreakpointIsExists(sessionID, addr)
			this.SetBreakpoint(sessionID, addr)
		else
			this.ClearBreakpoint(sessionID, addr)
		endif
	enddef

	def BreakpointIsExists(sessionID: number, addr: Address): bool
		return has_key(this._breakpoints, sessionID)
			&& has_key(this._breakpoints[sessionID], addr->string())
	enddef

	def GetBuffer(): buffer.Buffer
		return this._win.GetBuffer()
	enddef

	def GetCursorPos(): tuple<number, number>
		return this._win.GetCursorPos()
	enddef

	def Goto(addr: Address)
		var buf = this._win.GetBuffer()
		if buf.name != addr.FileName
			buf = buffer.Buffer.new(addr.FileName)
		endif

		this._win.SetBuffer(buf)
		this._win.SetCursor(addr.Lnum, addr.Col)
	enddef

	def ClearSessionBreakpoint(sessionID: number)
		if has_key(this._breakpoints, sessionID)
			remove(this._breakpoints, sessionID)
			sign_unplace($'{this.signGroup}-{sessionID}')
		endif
	enddef

	def ClearAllSessionBreakpoint()
		this._breakpoints
			->keys()
			->foreach((_, sessionID) => {
				sign_unplace($'{this.signGroup}-{sessionID}')
			})
		sign_undefine(this.signBreakpoint)
	enddef
endclass

export class REPLDebugUI
	var prompt: window.Window
	var code: DebugCodeWindow
	final _extends: dict<window.Window>

	def new()
		this.code = DebugCodeWindow.new()
	enddef

	def SetPrompt(prompt: buffer.Buffer, pos: string = '', height: number = 0)
		if this.prompt == null_object
			this.prompt = window.Window.new(pos, height, '')
		elseif height != 0
			this.prompt.Resize(height)
		endif

		this.prompt.SetBuffer(prompt)
		this.prompt.Execute('startinsert')
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

final debug = vim.IncID.new()

export abstract class REPLDebugBackend extends jb.Prompt
	var id = debug.ID()
	var _UI: REPLDebugUI
	var _OnInterruptCb: func()

	abstract def Prompt(): string
	abstract def HandleGoto(text: string): Address
	abstract def HandleToggleBreakpoint(text: string): Address
	abstract def MakeCommand(text: string): string

	def Bufname(): string
		return $'{trim(this.Prompt())}-{this.id}'
	enddef

	def Callback(_: channel, line: string)
		var break = this.HandleToggleBreakpoint(line)
		if break != null_object
			this._UI.code.ToggleBreakpoint(this.id, break)
			return
		endif

		var addr = this.HandleGoto(line)
		if addr != null_object
			this._UI.code.Goto(addr)
			return
		endif

		this.prompt.AppendLine(line)
	enddef

	def OnInterruptCb(F: func())
		this._OnInterruptCb = F
	enddef

	def InterruptCb()
		this._OnInterruptCb()
		super.InterruptCb()
	enddef

	def SetUI(ui: REPLDebugUI)
		this._UI = ui
	enddef
endclass

class MockREPLDebugBackend extends REPLDebugBackend
	def Prompt(): string
		return ''
	enddef

	def HandleGoto(_: string): Address
		return null_object
	enddef

	def HandleToggleBreakpoint(_: string): Address
		return null_object
	enddef

	def MakeCommand(path: string): string
		var [f, lnum, _] = path->split(':')
		this._UI.code.ToggleBreakpoint(this.id, Address.new(f, lnum->str2nr()))
		return ''
	enddef

	def Bufname(): string
		return ''
	enddef

	def Callback(_: channel, _: string)
	enddef

	def OnInterruptCb(F: func())
	enddef

	def InterruptCb()
	enddef

	def SetUI(ui: REPLDebugUI)
		this._UI = ui
	enddef

	def Send(_: string)
	enddef

	def Run()
	enddef
endclass

export class REPLDebugManager
	var _UI: REPLDebugUI
	var _Session: Ring

	def new()
		this._InitHightlight()
		this._UI = REPLDebugUI.new()
		var mock = MockREPLDebugBackend.new()
		mock.SetUI(this._UI)
		this._Session = Ring.new(mock)
	enddef

	def _InitHightlight()
		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term:  {reverse: true}},
			{name: 'REPLDebugStep', ctermfg: 'red', guifg: 'red', term:  {reverse: true}}
		])
	enddef

	def Open(repl: REPLDebugBackend, pos: string = '', count: number = 0)
		repl.Run()
		this._UI.SetPrompt(repl.prompt, pos, count)
		repl.OnInterruptCb(this._OnInterruptCb)
		repl.SetUI(this._UI)

		var cur = this._Session.Current<REPLDebugBackend>()
		if instanceof(cur, MockREPLDebugBackend)
			this._UI
				.code
				.GetBreakpoints(cur.id)
				->keys()
				->foreach((_, path) => {
					repl.Send(repl.MakeCommand(path))
				})
			this._Session.Remove<REPLDebugBackend>()
		endif

		this._Session.Add<REPLDebugBackend>(repl)
	enddef

	def _OnInterruptCb()
		this._UI.code.ClearSessionBreakpoint(this._Session.Current<REPLDebugBackend>().id)
		this._Session.Remove<REPLDebugBackend>()
		if this._Session.empty()
			if exists(':REPLDebugClose')
				execute('REPLDebugClose')
			endif
		endif
	enddef

	def NextSession()
		this._Session.SlideRight()
		var cur = this._Session.Current<REPLDebugBackend>()
		if cur.prompt == null_object
			return
		endif

		this._UI.SetPrompt(cur.prompt)
		cur.SetUI(this._UI)
	enddef

	def PrevSession()
		this._Session.SlideLeft()
		var cur = this._Session.Current<REPLDebugBackend>()
		if cur.prompt == null_object
			return
		endif

		this._UI.SetPrompt(cur.prompt)
		cur.SetUI(this._UI)
	enddef

	def ToggleBreakpoint()
		var cur = this._Session.Current<REPLDebugBackend>()
		if cur == null_object
			return
		endif

		var buf = this._UI.code.GetBuffer()
		var [lnum, col] = this._UI.code.GetCursorPos()
		var line = buf.GetOneLine(lnum)
		var cms = &commentstring->split('%s')
		if line =~ '^\s\{-\}$'
				|| (!empty(cms)
				&& line =~ $'^\s\{{-\}}{trim(cms[0])}')
				|| (len(cms) > 1
				&& line =~ $'^\s\{{-\}}{trim(cms[1])}')
			return
		endif

		cur.Send(cur.MakeCommand($'{buf.name}:{lnum}:{col}'))
	enddef

	def Close()
		this._UI.code.ClearAllSessionBreakpoint()
		this._Session.ForEach((repl: REPLDebugBackend) => {
			repl.prompt.Delete()
		})
	enddef
endclass
