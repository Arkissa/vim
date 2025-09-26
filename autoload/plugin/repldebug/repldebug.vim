vim9script

import autoload 'vim.vim'
import autoload 'job.vim' as jb
import autoload 'window.vim'
import autoload 'buffer.vim'
import autoload 'autocmd.vim'

type Ring = vim.Ring
type Async = vim.Async
type Buffer = buffer.Buffer
type Window = window.Window
type Autocmd = autocmd.Autocmd
type Terminal = buffer.Terminal
type Coroutine = vim.Coroutine

const group = 'REPLDebug'

export enum VariableTag
	Watch,
	Global,
	Local
endenum

export class Variable
	var Tag: VariableTag
	var Type: string
	var Name: string
	var Value: string

	def new(this.Tag, this.Type, this.Name, this.Value)
	enddef
endclass

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
	var Bufnr: number

	def new(this.FileName, this.Lnum)
		this.Bufnr = Buffer.new(this.FileName).bufnr
	enddef

	def newAll(this.FileName, this.Lnum, this.Col)
		this.Bufnr = Buffer.new(this.FileName).bufnr
	enddef

	def string(): string
		return this.Col == 0
			? $'{this.FileName}:{this.Lnum}'
			: $'{this.FileName}:{this.Lnum}:{this.Col}'
	enddef
endclass

class BreakpointUI
	const _sigName = 'REPLDebug-Variable'
	var _breakpoint: dict<tuple<number, Address>>

	def new()
		sign_define(this._sigName, {
			text: '●',
			texthl: 'REPLDebugBreakpoint',
		})
	enddef

	def IsExists(addr: Address): bool
		return has_key(this._breakpoint, addr->string())
	enddef

	def Break(addr: Address)
		var signID = sign_place(
			0,
			group,
			this._sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)


		this._breakpoint[addr->string()] = (signID, addr)
	enddef

	def Clear(addr: Address)
		var [signID, _] = remove(this._breakpoint, addr->string())
		sign_unplace(group, {buffer: addr.Bufnr, id: signID})
	enddef

	def Toggle(break: Address = null_object)
		var addr: Address

		if break != null_object
			addr = address
		else
			var win = window.Window.newCurrent()
			buf = win.GetBuffer()

			var [lnum, col] = bwin.GetCursorPosition()
			var line = buf.GetOneLine(lnum)
			addr = Address.newAll(line, lnum, col)
		endif

		if has_key(this._breakpoint, addr->string())
			this.Clear(addr)
		else
			this.Break(addr)
		endif
	enddef

	def ClearAll()
		for signID in this._breakpoint->values()->map((_, break) => break[0])
			sign_unplace(group, {id: signID})
		endfor
		sign_undefine(this._sigName)
	enddef
endclass

export class StepUI
	const _sigName = 'REPLDebug-Step'
	var _id: number

	def new()
		sign_define(this._sigName, {
			text: '=>',
			texthl: 'REPLDebugStep',
			linehl: 'CursorLine'
		})
	enddef

	def Set(addr: Address)
		sign_unplace(group, {id: signID})
		var _id	= sign_place(
			0,
			group,
			this._sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)
	enddef

	def Clear()
		sign_unplace(group, {id: signID})
		sign_undefine(this._sigName)
	enddef
endclass

enum REPLDebugMethod
	Step,
	FocusMe,
	ToggleBreakpoint

	static def Names(): list<string>
		return Method.values->mapnew((_, method) => method.name)
	enddef
endenum

export class REPLDebugUI
	var _step: StepUI
	var _code: Window
	var _scope: Window
	var _prompt: Window
	var _breakpoints BreakpointUI

	def new(conf: dict<any> = null_object)
		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term:  {reverse: true}},
			{name: 'REPLDebugStep', default: true, linksto: 'Normal'}
		])

		this.code = Window.newCurrent()

		var scopeConf = get(conf, 'scope', {})
		this._scope = Window.new(get(scopeConf, 'pos', ''), get(scopeConf, 'height', 0), 'REPLDebug-Scope')

		Autocmd.new('User')
			.Group(group)
			.Pattern(REPLDebugMethod.Names())
			.Replace()
			.Callback(this._Dispatch)
	enddef

	def Close()
		this._step.Clear()
		this._scope.Close()
		this._prompt.Close()
		this._breakpoints.ClearAll()
		autocmd_delete(REPLDebugMethod.Names()->mapnew((_, method) => {
			return {
				event: 'User',
				group: group,
				pattern: method}
		}))
	enddef

	def _Dispatch(opt: autocmd.EventArgs)
		if opt.event == ''
	enddef

	def _Step(opt: autocmd.EventArgs)
		var addr: Address = opt.data
		var buf = this._code.GetBuffer()
		if buf.bufnr != addr.Bufnr
			this._code.SetBuf(addr.bufnr)
		endif

		this._code.SetCursor(addr.Lnum, addr.Col)
		this._step.Set(addr)
		this._code.Feedkeys('z.', 'mx')
	enddef

	def _Breakpoint(opt: autocmd.EventArgs)
		var addr: Address = opt.data
		if this._breakpoints.IsExists(addr)
			this._breakpoints.Clear(addr)
		else
			this._breakpoints.Break(addr)
		endif
	enddef

	def _FocusMe(opt: autocmd.EventArgs)
		var buffers: tuple<Buffer, buffer.Prompt, Buffer> = opt.data
		var [code, prompt, scope] = buffers
		this._code.SetBuffer(code)
		this._prompt.SetBuffer(prompt)
		this._scope.SetBuffer(scope)
	enddef

	def ToggleBreakpoint()
		if exists('#User#REPLDebugToggleBreakPoint')
			var win = window.Window.newCurrent()
			buf = win.GetBuffer()

			var [lnum, col] = win.GetCursorPosition()
			var line = buf.GetOneLine(lnum)
			Autocmd.Do('', 'User', ['REPLDebugToggleBreakPoint'], [Address.newAll(buf.name, lnum, col)])
		endif
	enddef
endclass

final debug = vim.IncID.new()

export abstract class REPLDebugBackend extends jb.Prompt
	var id = debug.ID()
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

	def Send(_: string)
	enddef

	def Run()
	enddef
endclass

export class REPLDebugManager
	var _Session: Ring

	def new()
		this._InitHightlight()
		this._UI = REPLDebugUI.new()
		var mock = MockREPLDebugBackend.new()
		mock.SetUI(this._UI)
		this._Session = Ring.new(mock)
		Autocmd.new('BufWinEnter')
			.Group(this._Breakpoints)
			.Pattern([this.code->string()])
			.Callback(() => {
				Command.new('ToggleBreakpoint')
					.Buffer()
					.Callback(this.code.)
			})

		Autocmd.new('BufWinLeave')
			.Group(this._Breakpoints)
			.Pattern([this.code->string()])
			.Callback(() => {
				Command.Delete('ToggleBreakpoint', true)
			})
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

		var cur = this._Session.Peek()
		if instanceof(cur, MockREPLDebugBackend)
			this._UI
				.code
				.GetBreakpoints(cur.id)
				->keys()
				->foreach((_, path) => {
					repl.Send(repl.MakeCommand(path))
				})
			this._Session.Pop<REPLDebugBackend>()
		endif

		this._Session.Push(repl)
	enddef

	def _OnInterruptCb()
		this._UI.code.ClearSessionBreakpoint(this._Session.Peek().id)
		this._Session.Pop<REPLDebugBackend>()
		if this._Session.empty()
			if exists(':REPLDebugClose')
				execute('REPLDebugClose')
			endif
		endif
	enddef

	def NextSession()
		this._Session.SlideRight()
		var cur = this._Session.Peek()
		if cur.prompt == null_object
			return
		endif

		this._UI.SetPrompt(cur.prompt)
		cur.SetUI(this._UI)
	enddef

	def PrevSession()
		this._Session.SlideLeft()
		var cur = this._Session.Peek()
		if cur.prompt == null_object
			return
		endif

		this._UI.SetPrompt(cur.prompt)
		cur.SetUI(this._UI)
	enddef

	def ToggleBreakpoint()
		var cur = this._Session.Peek()
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

		var breakpoints = this._UI.GetBreakpointVar()
		var breakpoints: any = this._UI.code.GetVar('REPLDebugBreakpoints')
		if breakpoints == ''
			breakpoints = {}
		endif


		this._UI.code.SetVar('')
		this._UI.code.ToggleBreakpoint(this.id, Address.new(f, lnum->str2nr()))
		cur.Send(cur.MakeCommand($'{buf.name}:{lnum}:{col}'))
	enddef

	def Close()
		this._UI.code.ClearAllSessionBreakpoint()
		this._Session.ForEach((repl: REPLDebugBackend) => {
			repl.prompt.Delete()
		})
	enddef
endclass
