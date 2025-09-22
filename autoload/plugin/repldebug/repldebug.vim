vim9script

import autoload 'vim.vim'
import autoload 'job.vim' as jb
import autoload 'window.vim'
import autoload 'buffer.vim'

type Ring = vim.Ring
type Coroutine = vim.Coroutine
type AsyncWindow = window.Window

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

class DebugVariablesWindow extends AsyncWindow
	var _variables: dict<dict<Variable>> = {
		Watch: {},
		Global: {},
		Local: {},
	}

	def new()
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
		return [this.FileName, this.Lnum, this.Col]->join(':')
	enddef
endclass

class DebugCodeWindow
	const signGroup = 'REPLDebug'
	var _win: window.Window
	var _breakpoints: dict<dict<tuple<number, Address>>>

	def new()
		this._win = window.Window.newCurrent()
	enddef

	def GetBreakpoints(sessionID: number): dict<Address>
		return this._breakpoints[sessionID]
	enddef

	def SetBreakpoint(sessionID: number, breakID: number, addr: Address)
		var signName = $'{sessionID}-{breakID}'
		sign_define(signName, {
			text: '*',
			texthl: 'red',
		})

		this._breakpoints[sessionID][breakID] = (sign_place(0, $'{this.signGroup}-{sessionID}', signName, this._win.GetBufnr(), {lnum: addr.Lnum, priority: 110}), addr)
	enddef

	def DeleteBreakpoint(sessionID: number, breakID: number, addr: Address)
		var [signID, _] = remove(this._breakpoints[sessionID], breakID)
		sign_unplace(this.signGroup, {buffer: this._win.GetBufnr(), id: signID})
	enddef

	def BreakpointToggle(sessionID: number, breakID: number, addr: Address)
		if !this.BreakpointIsExistsByBreakID(sessionID, breakID)
			this.SetBreakpoint(sessionID, breakID, addr)
		else
			this.DeleteBreakpoint(sessionID, breakID, addr)
		endif
	enddef

	def GetBreakpointID(sessionID: number, addr: Address): number
		if has_key(this._breakpoints, sessionID)
			var addrstr = addr->string()
			for [breakID, [_, a]] in items(this._breakpoints[sessionID])
				if a->string() == addrstr
					return breakID
				endif
			endfor
		endif

		return -1
	enddef

	def BreakpointIsExists(sessionID: number, addr: Address): bool
		if !has_key(this._breakpoints, sessionID)
			return false
		endif

		return values(this._breakpoints[sessionID])->indexof((_, b) => b[1]->string() == addr->string()) != -1
	enddef

	def BreakpointIsExistsByBreakID(sessionID: number, breakID: number): bool
		return has_key(this._breakpoints, sessionID) && has_key(this._breakpoints[sessionID], breakID)
	enddef

	def Goto(addr: Address)
		var buf = this._win.GetBuffer()
		if buf.name != addr.FileName
			buf = buffer.Buffer.new(addr.FileName)
		endif

		this._win.SetBuffer(buf)
		this._win.SetCursor(addr.Lnum, addr.Col)
	enddef

	def DeleteSession(sessionID: number)
		if has_key(this._breakpoints, sessionID)
			var d = remove(this._breakpoints, sessionID)
			d->keys()->foreach((_, breakID) => {
				sign_undefine($'{sessionID}-{breakID}')
			})
			sign_unplace($'{this.signGroup}-{sessionID}')
		endif
	enddef
endclass

export class REPLDebugUI
	var prompt: window.Window
	var code: DebugCodeWindow
	final _extends: dict<window.Window>

	def new(prompt: buffer.Buffer)
		this.code = DebugCodeWindow.new()
		this.prompt = window.Window.newByBuffer(prompt)
		this.prompt.Execute('startinsert')
		this.prompt.OnSetBufPost((w) => {
			w.Execute('startinsert')
		})
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

export abstract class REPLDebugBackend extends jb.Prompt # {{{1
	var id = debug.ID()
	var _UI: REPLDebugUI
	var _OnInterruptCb: func()

	abstract def Prompt(): string # {{{2
	abstract def HandleGoto(text: string): Address
	abstract def HandleToggleBreakpoint(text: string): tuple<number, Address>
	abstract def MakeCommand(text: string): string

	def Bufname(): string
		return $'{trim(this.Prompt())}-{this.id}'
	enddef

	def Callback(_: channel, line: string) # {{{2
		var break = this.HandleToggleBreakpoint(line)
		if break != null_tuple
			var [breakID, addr] = break
			this._UI.code.BreakpointToggle(this.id, breakID, addr)
			return
		endif

		var addr = this.HandleGoto(line)
		if addr != null_object
			this._UI.code.Goto(addr)
			return
		endif

		this.prompt.AppendLine(line)
	enddef # }}}

	def OnInterruptCb(F: func()) # {{{2
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
endclass # }}}

export class REPLDebugManager
	var _UI: REPLDebugUI
	var _Session: Ring

	def Open(repl: REPLDebugBackend)
		repl.Run()
		this._UI = this._UI ?? REPLDebugUI.new(repl.prompt)
		repl.OnInterruptCb(this._OnInterruptCb)
		repl.SetUI(this._UI)

		if this._Session == null_object
			this._Session = Ring.new(repl)
		else
			this._Session.Add<REPLDebugBackend>(repl)
		endif

	enddef

	def _OnInterruptCb()
		this._UI.code.DeleteSession(this._Session.Current<REPLDebugBackend>().id)
		this._Session.Remove<REPLDebugBackend>()
	enddef

	def NextSession()
		this._Session.SlideRight()
	enddef

	def PrevSession()
		this._Session.SlideLeft()
	enddef

	def ToggleBreakpoint()
		var cur = this._Session.Current<REPLDebugBackend>()
		var buf = this._UI.code.GetBuffer()
		var [lnum, col] = this._UI.code.GetCursorPos()
		var cmd = cur.MakeCommand($'{buf.name}:{lnum}:{col}')
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
