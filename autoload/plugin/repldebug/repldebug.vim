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

		if !has_key(this._breakpoint, id)
			this._breakpoint[id] = {}
		endif

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
		for breaks in this._breakpoint->values()
			for break in breaks->values()
				sign_unplace(this.group, {id: break[0]})
			endfor
		endfor
		this._breakpoint = {}
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
		if this._id > 0
			sign_unplace(this.group, {id: this._id})
		endif

		this._id = sign_place(
			0,
			this.group,
			this._sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)
	enddef

	def Clear()
		if this._id > 0
			sign_unplace(this.group, {id: this._id})
		endif
	enddef
endclass

export enum Method
	Step,
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

export class Context
	var abort: bool
	var _buf: buffer.Buffer

	def new(this._buf)
	enddef

	def Abort()
		this.abort = true
	enddef

	def Write(line: string)
		this._buf.AppendLine(line)
	enddef
endclass

export abstract class Backend extends jb.Prompt
	static const group = 'REPLDebugBackend'

	var id = debug.ID()
	var handles: list<func(Context, string)>

	abstract def Prompt(): string
	abstract def BreakpointCommand(addr: tuple<bool, Address>): string

	def Bufname(): string
		return $'{trim(this.Prompt())}-{this.id}'
	enddef

	def ExitCb(job: job, code: number)
		this.RequestUIMethod(Method.Close)
		super.ExitCb(job, code)
	enddef

	def RequestUIMethod(pattern: Method, data: any = null)
		Method.Request(UI.group, pattern, data)
	enddef

	def FocusMe()
		def Breakpoint(backend: Backend, opt: autocmd.EventArgs)
			var data: list<Address> = opt.data
			var cmds = data->mapnew((_, addr) => backend.BreakpointCommand((opt.match == 'Breakpoint', addr)))

			for cmd in cmds
				backend.Send(cmd)
			endfor
		enddef

		Autocmd.new('User')
			.Group(group)
			.Pattern([Method.Breakpoint.name, Method.ClearBreakpoint.name])
			.Replace()
			.Callback(funcref(Breakpoint, [this]))

		Autocmd.new('User')
			.Group(group)
			.Pattern([Method.Close.name])
			.Replace()
			.Callback(this.Stop)

		this.RequestUIMethod(Method.FocusMe, (this.id, this.prompt))
	enddef

	def Callback(_: channel, line: string)
		var ctx = Context.new(this.prompt)
		for Handle in this.handles
			Handle(ctx, line)

			if ctx.abort
				break
			endif
		endfor
	enddef

	def Append(text: string)
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

	def _Break(opt: autocmd.EventArgs): Coroutine
		return Coroutine.new((addrs, match) => {
			for addr in addrs
				if match == Method.Breakpoint.name
					this.RequestUIMethod(Method.Breakpoint, (this.id, addr))
					this._breaks[addr->string()] = addr
				else
					this.RequestUIMethod(Method.ClearBreakpoint, (this.id, remove(this._breaks, addr->string())))
				endif
			endfor
		}, opt.data, opt.match)
	enddef

	def FocusMe()
		Autocmd.new('User')
			.Group(Backend.group)
			.Pattern([Method.Breakpoint.name, Method.ClearBreakpoint.name])
			.Replace()
			.Callback((opt) => {
				if opt.data == null || opt.data == null_list
					return
				endif

				AsyncIO.Await<vim.Void>(this._Break(opt))
			})
	enddef

	def Prompt(): string
		return ''
	enddef

	def Bufname(): string
		return ''
	enddef

	def Callback(_: channel, _: string)
	enddef

	def InterruptCb()
		Method.Request(Backend.group, Method.Breakpoint, this._breaks->values())
		Method.Request(Backend.group, Method.ClearAllBreakpoint, this.id)
	enddef

	def Send(_: string)
	enddef

	def Run()
	enddef
endclass

class UI extends vim.Async
	var _step: StepUI
	var _code: Window
	var _prompt: Window
	var _breakpoints: BreakpointUI
	var _Session: Ring

	static const group = 'REPLDebugUI'

	def new()
		this._code = Window.newCurrent()
		this._breakpoints = BreakpointUI.new()
		this._step = StepUI.new()
		this._Session = Ring.new(MockBackend.new())
		this._Session.Peek().FocusMe()

		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term:  {reverse: true}},
			{name: 'REPLDebugStep', default: true, linksto: 'Function'}
		])

		Autocmd.new('User')
			.Group(group)
			.Pattern(Method.Names())
			.Replace()
			.Callback(this._Dispatch)
	enddef

	def _Dispatch(opt: autocmd.EventArgs)
		if opt.match == Method.Step.name
			this.Await<vim.Void>(this._Step(opt))
		elseif opt.match == Method.Breakpoint.name
			this.Await<vim.Void>(this._Breakpoint(opt))
		elseif opt.match == Method.ClearBreakpoint.name
			this.Await<vim.Void>(this._ClearBreakpoint(opt))
		elseif opt.match == Method.ClearAllBreakpoint.name
			this.Await<vim.Void>(this._ClearAllBreakpoint(opt))
		elseif opt.match == Method.FocusMe.name
			this.Await<vim.Void>(this._FocusMe(opt))
		else
			this.Close()
		endif
	enddef

	def _Step(opt: autocmd.EventArgs): Coroutine
		return Coroutine.new((addr: Address) => {
			var buf = this._code.GetBuffer()
			if buf.bufnr != addr.Bufnr
				this._code.SetBuf(addr.Bufnr)
				var ft = this._code.GetBuffer().GetVar('&filetype')
				if ft == ""
					this._code.Execute('filetype detect')
				endif
			endif

			this._code.SetCursor(addr.Lnum, addr.Col)
			this._step.Set(addr)
			this._code.FeedKeys('z.', 'mx')
		}, opt.data)
	enddef

	def _Finish()
		this._step.Clear()
		this._prompt.Close()
		this._prompt = null_object
		this._breakpoints.ClearAll()
	enddef

	def _Breakpoint(opt: autocmd.EventArgs): Coroutine
		var data: tuple<number, Address> = opt.data
		var [id, addr] = data

		return Coroutine.new(this._breakpoints.Break, id, addr)
	enddef

	def _ClearBreakpoint(opt: autocmd.EventArgs): Coroutine
		var data: tuple<number, Address> = opt.data
		var [id, addr] = data

		return Coroutine.new(this._breakpoints.Clear, id, addr)
	enddef

	def _ClearAllBreakpoint(opt: autocmd.EventArgs): Coroutine
		return Coroutine.new(this._breakpoints.ClearAllByID, opt.data)
	enddef

	def _FocusMe(opt: autocmd.EventArgs): Coroutine
		var backend: tuple<number, buffer.Prompt> = opt.data
		var [id, prompt] = backend

		return Coroutine.new(() => {
			var conf = get(g:, 'REPLDebugConfig', {})

			if this._prompt == null_object
				var promptConf = get(conf, 'prompt', {})
				this._prompt = Window.new(get(promptConf, 'pos', 'horizontal botright'), get(promptConf, 'height', 0))

				Autocmd.new('WinClosed')
					.Group(UI.group)
					.Pattern([this._prompt.winnr->string()])
					.Once()
					.Callback(function(Method.Request, [Backend.group, Method.Close, null]))
			endif

			this._prompt.SetBuffer(prompt)
			execute('startinsert')
			this._Session.SwitchOf((b) => b.id == id)
		})
	enddef

	def Open(repl: Backend)
		if instanceof(this._Session.Peek(), MockBackend)
			AsyncIO.Run(Coroutine.new(this._Session.Pop().InterruptCb))
		endif

		this._Session.Push(repl)
		repl.Run()
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
		var addr = Address.new(buf.name, lnum)

		var backend = this._Session.Peek()
		var match = this._breakpoints.IsExists(backend.id, addr) ? Method.ClearBreakpoint : Method.Breakpoint
		Method.Request('REPLDebugBackend', match, [addr])
	enddef
endclass

export const REPLDebugUI = UI.new()
