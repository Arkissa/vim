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

	def _Draw(scope: dict<Variable>): Coroutine
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
	const group = 'REPLDebug-Variable'
	var _breakpoint: dict<dict<tuple<number, Address>>>

	def new()
		sign_define(this._sigName, {
			text: '●',
			texthl: 'REPLDebugBreakpoint',
		})
	enddef

	def IsExists(id: number, addr: Address): bool
		return has_key(this._breakpoint, id) && has_key(this._breakpoint[id], addr->string())
	enddef

	def Break(id: number, addr: Address)
		var signID = sign_place(
			0,
			this.group,
			this._sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)

		this._breakpoint[id][addr->string()] = (signID, addr)
	enddef

	def Clear(id: number, addr: Address)
		if !has_key(this._breakpoint, id)
			return
		endif

		var breaks = this._breakpoint[id]
		var [signID, _] = remove(breaks, addr->string())
		sign_unplace(this.group, {buffer: addr.Bufnr, id: signID})
	enddef

# 	def Toggle(break: Address = null_object)
# 		var addr: Address

# 		if break != null_object
# 			addr = address
# 		else
# 			var win = window.Window.newCurrent()
# 			buf = win.GetBuffer()

# 			var [lnum, col] = bwin.GetCursorPosition()
# 			var line = buf.GetOneLine(lnum)
# 			addr = Address.newAll(line, lnum, col)
# 		endif

# 		if this.IsExists(addr)
# 			this.Clear(addr)
# 		else
# 			this.Break(addr)
# 		endif
# 	enddef

	def ClearAllByID(id: number)
		if !has_key(this._breakpoint, id)
			return
		endif

		var breaks = this._breakpoint[id]
		for signID in breaks->values()->map((_, break: tuple<number, Address>) => break[0])
			sign_unplace(this.group, {id: signID})
		endfor
	enddef

	def ClearAll()
		for signID in this._breakpoint->values()->map((_, break) => break[0])
			sign_unplace(this.group, {id: signID})
		endfor
		sign_undefine(this._sigName)
	enddef
endclass

class StepUI
	const _sigName = 'REPLDebug-Step'
	const group = 'REPLDebug-Step'
	var _id: number

	def new()
		sign_define(this._sigName, {
			text: '=>',
			texthl: 'REPLDebugStep',
			linehl: 'CursorLine'
		})
	enddef

	def Set(addr: Address)
		sign_unplace(this.group, {id: this._id})
		this._id = sign_place(
			0,
			this.group,
			this._sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)
	enddef

	def Clear()
		sign_unplace(this.group, {id: this._id})
		sign_undefine(this._sigName)
	enddef
endclass

export enum Method
	Step,
	# Scope,
	# Stack,
	Close,
	FocusMe,
	Breakpoint,
	ClearBreakpoint,
	ClearAllBreakpoint

	static def Names(): list<string>
		return Method.values->mapnew((_, method) => method.name)
	enddef

	static def Request(group: string, pattern: Method, data: any = null)
		if exists($'#{group}#User#{pattern.name}')
			Autocmd.Do(group, 'User', [pattern.name], data)
		endif
	enddef
endenum

final debug = vim.IncID.new()

export abstract class Backend extends jb.Prompt
	const group = 'REPLDebugBackend'

	var id = debug.ID()
	var scope: buffer.Buffer

	abstract def Prompt(): string
	abstract def BreakpointCommand(addr: tuple<bool, Address>): string
	abstract def HandleStepFromRPEL(text: string): Address
	abstract def HandleFocusMeFromRPEL(text: string): Address
	abstract def HandleSetBreakpointFromREPL(text: string): Address
	abstract def HandleClearBreakpointFromREPL(text: string): Address

	def Bufname(): string
		return $'{trim(this.Prompt())}-{this.id}'
	enddef

	def InterruptCb()
		this.RequestUIMethod(Method.Close)
	enddef

	def RequestUIMethod(pattern: Method, data: any = null)
		Method.Request(UI.group, pattern, data)
	enddef

	def FocusMe()
		def Breakpoint(b: Backend, opt: autocmd.EventArgs)
			var data: list<Address> = opt.data
			var cmds = data->mapnew((_, addr) => b.BreakpointCommand((opt.event == 'Breakpoint', addr)))

			AsyncIO.Run(Coroutine.new(
				(addrs, backend) => {
					for addr in addrs
						backend.Send(addr)
					endfor
				},
				cmds,
				b))
		enddef

		Autocmd.new('User')
			.Group(this.group)
			.Pattern(['Breakpoint', 'ClearBreakpoint'])
			.Replace()
			.Callback(funcref(Breakpoint, [this]))

		# this.RequestUIMethod(Method.FocusMe, (this.id, this.prompt, this.pty, this.stack)))
		this.RequestUIMethod(Method.FocusMe, (this.id, this.prompt, this.pty))
	enddef

	def Run()
		# this.stack = buffer.Buffer.new($'REPLDebugBackend-Stack-{this.id}')
		super.Run()
	enddef

	def Callback(_: channel, line: string)
		var addr: Address = this.HandleFocusMeFromREPL(line)
		if addr != null_object
			this.FocusMe()
			this.RequestUIMethod(Method.Step, addr)
			return
		endif

		addr = this.HandleSetBreakpointFromREPL(line)
		if addr != null_object
			this.RequestUIMethod(Method.Breakpoint, (this.id, addr))
			return
		endif

		addr = this.HandleClearBreakpointFromREPL(line)
		if addr != null_object
			this.RequestUIMethod(Method.ClearBreakpoint, (this.id, addr))
			return
		endif

		addr = this.HandleStepFromREPL(line)
		if addr != null_object
			this.RequestUIMethod(Method.Step, addr)
			return
		endif

		this.prompt.AppendLine(line)
	enddef
endclass

class MockBackend extends Backend
	var _breaks: dict<Address> = {}

	def Cmd(): string
		return ''
	enddef

	def BreakpointCommand(_: tuple<bool, Address>): string
		return ''
	enddef

	def FocusMe()
		Autocmd.new('User')
			.Group(this.group)
			.Pattern([Method.Breakpoint.name, Method.ClearBreakpoint.name])
			.Replace()
			.Callback((opt) => {
				if opt.data == null || opt.data == null_string
					return
				endif

				for addr in opt.data
					if opt.event == Method.Breakpoint.name
						this.RequestUIMethod(Method.Breakpoint, addr)
						this._breaks[addr->string()] = addr
					else
						this.RequestUIMethod(Method.ClearBreakpoint, remove(this._breaks, addr->string()))
					endif
				endfor
			})
	enddef

	def Prompt(): string
		return ''
	enddef

	def Bufname(): string
		return ''
	enddef

	def HandleStepFromRPEL(_: string): Address
		return null_object
	enddef

	def HandleSetBreakpointFromREPL(_: string): Address
		return null_object
	enddef

	def HandleClearBreakpointFromREPL(_: string): Address
		return null_object
	enddef

	def Callback(_: channel, _: string)
	enddef

	def InterruptCb()
		Method.Request(this.group, Method.Breakpoint, this._breaks->values())
	enddef

	def Send(_: string)
	enddef

	def HandleFocusMeFromRPEL(_: string): Address
		return null_object
	enddef

	# def HandleScopeFromRPEL(_: string): list<Variable>
	# 	return null_list
	# enddef

	def Run()
	enddef
endclass

class UI
	var _pty: Window
	var _step: StepUI
	var _code: Window
	# var _scope: ScopeUI
	# var _stack: Window
	var _prompt: Window
	var _breakpoints: BreakpointUI
	var _Session = Ring.new(MockBackend.new())

	static const group = 'REPLDebugUI'

	def new()
		this._code = Window.newCurrent()
		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term:  {reverse: true}},
			{name: 'REPLDebugStep', default: true, linksto: 'Normal'}
		])

		Autocmd.new('User')
			.Group(group)
			.Pattern(Method.Names())
			.Replace()
			.Callback(this._Dispatch)
	enddef

	def _Dispatch(opt: autocmd.EventArgs)
		if opt.event == Method.Step.name
			this._Step(opt)
		elseif opt.event == Method.Breakpoint.name
			this._Breakpoint(opt)
		elseif opt.event == Method.ClearBreakpoint.name
			this._ClearBreakpoint(opt)
		elseif opt.event == Method.FocusMe.name
			this._FocusMe(opt)
		else
			this.Close()
		endif
	enddef

	def _Step(opt: autocmd.EventArgs)
		var addr: Address = opt.data
		var buf = this._code.GetBuffer()
		if buf.bufnr != addr.Bufnr
			this._code.SetBuf(addr.Bufnr)
		endif

		this._code.SetCursor(addr.Lnum, addr.Col)
		this._step.Set(addr)
		this._code.FeedKeys('z.', 'mx')
	enddef

	def _Finish()
		this._step.Clear()
		# this._scope.Close()
		this._prompt.Close()
		this._breakpoints.ClearAll()
		autocmd_delete([{group: group, event: 'User', pattern: Method.Names()}])
	enddef

	def _Stack(opt: autocmd.EventArgs)
		var data: string = opt.data
		if data == ""
			this._stack.GetBuffer().Clear()
		else
			this._stack.AppendLine(data)
		endif
	enddef

	def _Breakpoint(opt: autocmd.EventArgs)
		var data: tuple<number, Address> = opt.data
		var [id, addr] = data
		this._breakpoints.Break(id, addr)
	enddef

	def _ClearBreakpoint(opt: autocmd.EventArgs)
		var data: tuple<number, Address> = opt.data
		var [id, addr] = data
		this._breakpoints.Clear(id, addr)
	enddef

	def _ClearAllBreakpoint(opt: autocmd.EventArgs)
		var id: number = opt.data
		this._breakpoints.ClearAllByID(id)
	enddef

	def _FocusMe(opt: autocmd.EventArgs)
		var conf = get(g:, 'REPLDebugConfig', {})

		# if this._scope == null_object
		# 	var scopeConf = get(conf, 'scope', {})
		# 	this._scope = Window.new(get(scopeConf, 'pos', 'vertical rightbelow'), get(scopeConf, 'height', 0))
		# endif
		# if this._stack == null_object
		# 	var stackConf = get(conf, 'stack', {})
		# 	this._stack = Window.new(get(stackConf, 'pos', 'vertical rightbelow'), get(stackConf, 'height', 0))
		# endif

		if this._pty == null_object
			var ptyConf = get(conf, 'pty', {})
			this._pty = Window.new(get(ptyConf, 'pos', 'horizontal rightbelow'), get(ptyConf, 'height', 0))
		endif

		if this._prompt == null_object
			var promptConf = get(conf, 'prompt', {})
			this._prompt = Window.new(get(promptConf, 'pos', 'horizontal botright'), get(promptConf, 'height', 0))
		endif

		var backend: tuple<number, buffer.Prompt, buffer.Terminal, buffer.Buffer> = opt.data
		# var [id, prompt, pty, stack] = backend
		var [id, prompt, pty] = backend

		this._pty.SetBuffer(pty)
		# this._stack.SetBuffer(stack)
		this._prompt.SetBuffer(prompt)
		this._Session.SwitchOf((b) => b.id == id)
	enddef

	def Open(repl: Backend)
		if instanceof(this._Session.Peek(), MockBackend)
			this._Session.Pop().InterruptCb()
		endif

		this._Session.Push(repl)
		repl.FocusMe()
	enddef

	def Close()
		this._Session.Pop()

		if this._Session->empty()
			this._Session.Push(MockBackend.new())
			this._Finish()
		endif

		this._Session.Peek().FocusMe()
	enddef

	def Next()
		this._Session.SlideRight()
		this._Session.Peek().FocusMe()
	enddef

	def Prev()
		this._Session.SlideLeft()
		this._Session.Peek().FocusMe()
	enddef

	def ToggleBreakpoint()
		var win = Window.newCurrent()
		var buf = win.GetBuffer()
		var [lnum, col] = win.GetCursorPos()
		var line = buf.GetOneLine(lnum)

		var cms = &commentstring->split('%s')
		if line =~ '^\s\{-\}$'
				|| (!empty(cms)
				&& line =~ $'^\s\{{-\}}{trim(cms[0])}')
				|| (len(cms) > 1
				&& line =~ $'^\s\{{-\}}{trim(cms[1])}')
			return
		endif
		var addr = Address.newAll(buf.name, lnum, col)

		var backend = this._Session.Peek()
		var event = this._breakpoints.IsExists(backend.id, addr) ? Method.ClearBreakpoint : Method.Breakpoint
		Method.Request('REPLDebugBackend', event, [addr])
	enddef
endclass

export const REPLDebugUI = UI.new()
