vim9script

import autoload 'vim.vim'
import autoload 'job.vim' as jb
import autoload 'window.vim'
import autoload 'buffer.vim'
import autoload 'autocmd.vim'

type Ring = vim.Ring
type Async = vim.Async
type Window = window.Window
type Autocmd = autocmd.Autocmd
type Coroutine = vim.Coroutine

const AsyncIO = vim.AsyncIO

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

class ScopeUI
	var _win: window.Window
	const _scopeName = 'REPLDebugScope'
	const _scopeBufname = 'REPLDebug-Scope'

	def new(pos: string, height: number)
		this._win = window.Window.new(pos, height, this._scopeBufname)
	enddef

	def Refresh(vars: list<Variable>)
		var scope = {}
		for v in vars
			scope[v.Tag.name][v.Name] = v
		endfor

		AsyncIO.Await(this._Draw(scope))
	enddef

	def _MaxLength(d: list<Variable>): tuple<number, number, number>
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

	def _Banner(d: list<Variable>): list<string>
		var [tl, nl, vl] = this._MaxLength(d)

		var format = $'%{tl}s %{nl}s %{vl}s'
		var lines = [printf(format, 'Type', 'Name', 'Value')]
		for v in values(d)
			lines->add(printf(format, v.Type, v.Name, v.Value))
		endfor

		return lines
	enddef

	def _Draw(scope: dict<Variabale>): Coroutine
		return Coroutine.new((variables, buf) => {
			var lines = []

			for [tag, vars] in variables->items()
				lines->add($'{tag} Variables:')
				lines->extend(this._Banner(vars))
			endfor

			buf.Clear()
			buf.SetLine(lines)
		}, scope, this._win.GetBuffer())
	enddef
endclass

export class Address
	var FileName: string
	var Lnum: number
	var Col: number
	var Bufnr: number

	def new(this.FileName, this.Lnum)
		this.Bufnr = buffer.Buffer.new(this.FileName).bufnr
	enddef

	def newAll(this.FileName, this.Lnum, this.Col)
		this.Bufnr = buffer.Buffer.new(this.FileName).bufnr
	enddef

	def string(): string
		return this.Col < 1
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

class StepUI
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

export enum REPLDebugMethod
	Step,
	Scope,
	Finish,
	FocusMe,
	ToggleBreakpoint

	static def Names(): list<string>
		return Method.values->mapnew((_, method) => method.name)
	enddef

	static def Request(group, pattern: REPLDebugMethod, data: any = null)
		if exists($'#{group}#User#{pattern.name}')
			Autocmd.Do(group, 'User', [pattern.name], data)
		endif
	enddef
endenum

final debug = vim.IncID.new()

export abstract class REPLDebugBackend extends jb.Prompt
	var id = debug.ID()
	var scope: buffer.Buffer

	const REPLDebugBackendGroup = 'REPLDebugBackend'

	abstract def Prompt(): string
	abstract def Bufname(): string
	abstract def HandleStep(text: string): Address
	abstract def HandleScope(text: string): list<Variable>
	abstract def HandleFocusMe(text: string): tuple<buffer.Prompt, buffer.Terminal, buffer.Buffer, Address>
	abstract def HandleToggleBreakpoint(text: string): Address

	def RequestUIMethod(pattern: string, data: any = null)
		REPLDebugMethod.Request(REPLDebugUI.group, 'User', [pattern], data)
	enddef

	def Bufname(): string
		return $'{trim(this.Prompt())}-{this.id}'
	enddef

	def Callback(_: channel, line: string)
		var scope = this.HandleScope(line)
		if scope != null_list
			this.RequestUIMethod(REPLDebugMethod.Scope, scope)
			return
		endif

		var addr = this.HandleStep(line)
		if addr != null_object
			this.RequestUIMethod(REPLDebugMethod.Step, addr)
			return
		endif

		var break = this.HandleToggleBreakpoint(line)
		if break != null_object
			this.RequestUIMethod(REPLDebugMethod.ToggleBreakpoint, break)
			return
		endif

		var focusMe = this.HandleFocusMe(line)
		if focusMe != null_tuple
			var [prompt, pty, scope, addr] = focusMe
			this.RequestUIMethod(REPLDebugMethod.FocusMe, (prompt, pty, scope)))
			this.RequestUIMethod(REPLDebugMethod.Step, addr)
			return
		endif

		this.prompt.AppendLine(line)
	enddef

	def InterruptCb()
		super.InterruptCb()
	enddef

	def Run()
		this.scope = buffer.Buffer.new()
		super.Run()
	enddef
endclass

class MockREPLDebugBackend extends REPLDebugBackend
	var _breaks: list<Address> = []
	const _togglePoint = Autocmd.new('ToggleBreakpoint')
		.Group(this.REPLDebugBackendGroup)
		.Callback((opt) => {
			this._breaks->extend(opt.data)
			this.RequestUIMethod(REPLDebugMethod.ToggleBreakpoint, breaks[-1])
		})

	def Prompt(): string
		return ''
	enddef

	def Bufname(): string
		return ''
	enddef

	def HandleStep(_: string): Address
		return null_object
	enddef

	def HandleToggleBreakpoint(_: string): Address
		return null_object
	enddef

	def Callback(_: channel, _: string)
	enddef

	def InterruptCb()
		REPLDebugMethod.Request(this.REPLDebugBackendGroup, REPLDebugMethod.ToggleBreakpoint, this.breaks)
	enddef

	def Send(_: string)
	enddef

	def HandleFocusMe(_: string): tuple<buffer.Prompt, Address>
		return null_tuple
	enddef

	def HandleScope(_: string): list<Variable>
		return null_list
	enddef

	def Run()
	enddef
endclass

export class REPLDebugUI
	var _pty: Window
	var _step: StepUI
	var _code: Window
	var _scope: ScopeUI
	var _prompt: Window
	var _breakpoints BreakpointUI

	static const group = 'REPLDebugUI'

	def new()
		this.code = Window.newCurrent()
		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term:  {reverse: true}},
			{name: 'REPLDebugStep', default: true, linksto: 'Normal'}
		])

		Autocmd.new('User')
			.Group(group)
			.Pattern(REPLDebugMethod.Names())
			.Replace()
			.Callback(this._Dispatch)
	enddef

	def _Dispatch(opt: autocmd.EventArgs)
		if opt.event == REPLDebugMethod.Step.name
			this._Step(opt)
		elseif opt.event == REPLDebugMethod.ToggleBreakpoint.name
			this._Breakpoint(opt)
		elseif opt.event == REPLDebugMethod.FocusMe.name
			this._FocusMe(opt)
		else
			this._Finish()
		endif
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

	def _Finish()
		this._step.Clear()
		this._scope.Close()
		this._prompt.Close()
		this._breakpoints.ClearAll()
		autocmd_delete({group: group, pattern: REPLDebugMethod.Names()})
	enddef

	def _Scope(opt: autocmd.EventArgs)
		var variables: list<Variable> = opt.data
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
		var conf = get(g:, 'REPLDebugConfig', {})

		if this._scope == null_object
			var scopeConf = get(conf, 'scope', {})
			this._scope = Window.new(get(scopeConf, 'pos', 'vertical rightbelow'), get(scopeConf, 'height', 0))
		endif

		if this._pty == null_object
			var ptyConf = get(conf, 'pty', {})
			this._pty = Window.new(get(ptyConf, 'pos', 'horizontal rightbelow'), get(ptyConf, 'height', 0))
		endif

		if this._prompt == null_object
			var promptConf = get(conf, 'prompt', {})
			this._prompt = Window.new(get(promptConf, 'pos', 'botright'), get(promptConf, 'height', 0))
		endif

		var backend: tuple<buffer.Prompt, buffer.Terminal, buffer.Buffer> = opt.data
		var [prompt, pty, scope] = backend

		this._pty.SetBuffer(pty)
		this._scope.SetBuffer(scope)
		this._prompt.SetBuffer(prompt)
	enddef

	static def ToggleBreakpoint()
		var win = Window.newCurrent()
		buf = win.GetBuffer()

		var cms = &commentstring->split('%s')
		if line =~ '^\s\{-\}$'
				|| (!empty(cms)
				&& line =~ $'^\s\{{-\}}{trim(cms[0])}')
				|| (len(cms) > 1
				&& line =~ $'^\s\{{-\}}{trim(cms[1])}')
			return
		endif
		var [lnum, col] = win.GetCursorPosition()
		var line = buf.GetOneLine(lnum)
		REPLDebugMethod.Request('REPLDebugBackend', 'ToggleBreakpoint', [Address.newAll(buf.name, lnum, col)])
	enddef
endclass
