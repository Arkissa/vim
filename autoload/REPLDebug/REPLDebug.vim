vim9script

import 'vim.vim'
import 'job.vim' as jb
import 'window.vim'
import 'buffer.vim'
import 'autocmd.vim'

type Ring = vim.Ring
type Async = vim.Async
type Window = window.Window
type Autocmd = autocmd.Autocmd
type Coroutine = vim.Coroutine

const AsyncIO = vim.AsyncIO

enum Host # {{{1
	REPLDebugUI,
	REPLDebugBackend
endenum # }}}

export class Rpc # {{{1
	var method: string
	var args: list<any>

	def new(this.method, ...args: list<any>) # {{{2
		this.args = args
	enddef # }}}

	def string(): string # {{{2
		return $'{this.method}({trim(this.args->string(), '[]')})'
	enddef # }}}
endclass # }}}

export enum Server # {{{1
	Step,
	Session,
	Monitor,
	Breakpoint

	static def Names(): list<string> # {{{2
		return Server.values->mapnew((_, method) => method.name)
	enddef # }}}

	static def Request(host: Host, server: Server, ...rpc: list<Rpc>) # {{{2
		if exists($'#{host.name}#User#{server.name}')
			Autocmd.Do(host.name, 'User', [server.name], rpc)
		endif
	enddef # }}}
endenum # }}}

export class Address # {{{1
	var FileName: string
	var Lnum: number
	var Col: number
	var Bufnr: number

	def new(this.FileName, this.Lnum) # {{{2
		this.FileName = fnamemodify(this.FileName, ':p:.')
		this.Bufnr = buffer.Buffer.new(this.FileName).bufnr
	enddef # }}}

	def newAll(this.FileName, this.Lnum, this.Col) # {{{2
		this.FileName = fnamemodify(this.FileName, ':p:.')
		this.Bufnr = buffer.Buffer.new(this.FileName).bufnr
	enddef # }}}

	def string(): string # {{{2
		return this.Col < 1
			? $'{this.FileName}:{this.Lnum}'
			: $'{this.FileName}:{this.Lnum}:{this.Col}'
	enddef # }}}
endclass # }}}

final debug = vim.IncID.new()

export class Context # {{{1
	var abort: bool
	var _buf: buffer.Buffer

	def new(this._buf) # {{{2
	enddef # }}}

	def Abort() # {{{2
		this.abort = true
	enddef # }}}

	def Write(line: string) # {{{2
		this._buf.AppendLine(line)
	enddef # }}}
endclass # }}}

export abstract class Backend extends jb.Prompt # {{{1
	var id = debug.ID()
	var handles: list<func(Context, string)>

	abstract def Prompt(): string
	abstract def BreakpointCommand(addr: Address): string
	abstract def ClearBreakpointCommand(breakID: number, addr: Address): string

	def Bufname(): string # {{{2
		return $'{trim(this.Prompt())}-{this.id}'
	enddef # }}}

	def GetBreakID(): number
		return this._breakID.ID()
	enddef

	def ExitCb(job: job, code: number) # {{{2
		this.RequestUIServer(Server.Session, Rpc.new('Stop'))
		super.ExitCb(job, code)
		if this.prompt.IsExists()
			this.prompt.Delete()
		endif
	enddef # }}}

	def RequestUIServer(server: Server, ...rpcs: list<Rpc>) # {{{2
		call(function(Server.Request, [Host.REPLDebugUI, server]), rpcs)
	enddef # }}}

	def FocusMe() # {{{2
		def Break(addrs: list<Address>) # {{{3
			for addr in addrs
				this.Send(this.BreakpointCommand(addr))
			endfor
		enddef # }}}

		def Clear(breakID: number, addr: Address) # {{{3
			this.Send(this.ClearBreakpointCommand(breakID, addr))
		enddef # }}}

		def Brkpit(opt: autocmd.EventArgs) # {{{3
			if opt.data == null
				return
			endif

			var rpcs: list<Rpc> = opt.data
			for rpc in rpcs
				if rpc.args->empty()
					continue
				endif

				call(rpc.method == 'Break' ? Break : Clear, rpc.args)
			endfor
		enddef # }}}

		Autocmd.new('User')
			.Group(Host.REPLDebugBackend.name)
			.Pattern([Server.Breakpoint.name])
			.Replace()
			.Callback(Brkpit)

		this.RequestUIServer(Server.Session, Rpc.new('FocusMe', this.id, this.prompt))
	enddef # }}}

	def Callback(_: channel, line: string) # {{{2
		var i = 0
		var ctx = Context.new(this.prompt)

		while i < len(this.handles)
			call(this.handles[i], [ctx, line])

			if ctx.abort
				break
			endif

			i += 1
		endwhile

		if i >= len(this.handles)
			ctx.Write(line)
		endif
	enddef # }}}
endclass # }}}

class MockBackend extends Backend # {{{1
	var _breaks: dict<Address> = {}

	def Cmd(): string # {{{2
		return ''
	enddef # }}}

	def BreakpointCommand(_: Address): string # {{{2
		return ''
	enddef # }}}

	def ClearBreakpointCommand(_: number, _: Address): string # {{{2
	enddef # }}}

	def FocusMe() # {{{2
		def Clear(_: number, addr: Address) # {{{3
			this.RequestUIServer(Server.Breakpoint, Rpc.new('Clear', this.id, addr))
			remove(this._breaks, addr->string())
		enddef # }}}

		def Break(addrs: list<Address>) # {{{3
			for addr in addrs
				this.RequestUIServer(Server.Breakpoint, Rpc.new('Break', this.id, this.id, addr))
				this._breaks[addr->string()] = addr
			endfor
		enddef # }}}

		Autocmd.new('User')
			.Group(Host.REPLDebugBackend.name)
			.Pattern([Server.Breakpoint.name])
			.Replace()
			.Callback((opt) => {
				if opt.data == null
					return
				endif

				var rpcs: list<Rpc> = opt.data

				for rpc in rpcs
					call(rpc.method == 'Break' ? Break : Clear, rpc.args)
				endfor
			})
	enddef # }}}

	def Prompt(): string # {{{2
		return ''
	enddef # }}}

	def Bufname(): string # {{{2
		return ''
	enddef # }}}

	def Callback(_: channel, _: string) # {{{2
	enddef # }}}

	def InterruptCb() # {{{2
		var breaks = this._breaks->values()
		this._breaks = {}
		var co = Coroutine.new(() => {
			Server.Request(Host.REPLDebugBackend, Server.Breakpoint, Rpc.new('Break', breaks))
			this.RequestUIServer(Server.Breakpoint, Rpc.new('ClearAllByID', this.id))
		})

		co.SetDelay(1000) # Wait for REPL running.
		AsyncIO.Run(co)
	enddef # }}}

	def Send(_: string) # {{{2
	enddef # }}}

	def Run() # {{{2
	enddef # }}}
endclass # }}}

class Bp # {{{1
	var id: number
	var sign: number
	var addr: Address

	def new(this.id, this.sign, this.addr) # {{{2
	enddef # }}}
endclass # }}}

class BreakpointUI # {{{1
	const _sigName = 'REPLDebug-Variable'
	const _group = 'REPLDebug-Variable'

	var _breakpoints: dict<dict<Bp>> = {}

	def new() # {{{2
		sign_define(this._sigName, {
			text: '●',
			texthl: 'REPLDebugBreakpoint',
		})
	enddef # }}}

	def GetBreakpoint(sessionID: number, addr: Address): Bp # {{{2
		if !has_key(this._breakpoints, sessionID)
			return null_object
		endif

		var key = addr->string()
		if !has_key(this._breakpoints[sessionID], key)
			return null_object
		endif

		return this._breakpoints[sessionID][key]
	enddef # }}}

	def RpcBreak(sessionID: number, breakID: number, addr: Address) # {{{2
		var signID = sign_place(
			0,
			this._group,
			this._sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)

		if !has_key(this._breakpoints, sessionID)
			this._breakpoints[sessionID] = {}
		endif

		this._breakpoints[sessionID][addr->string()] = Bp.new(breakID, signID, addr)
	enddef # }}}

	def RpcClear(sessionID: number, addr: Address) # {{{2
		if !has_key(this._breakpoints, sessionID)
			return
		endif

		var breaks = this._breakpoints[sessionID]
		var break = remove(breaks, addr->string())
		sign_unplace(this._group, {buffer: addr.Bufnr, id: break.sign})
	enddef # }}}

	def RpcClearAllByID(sessionID: number) # {{{2
		if !has_key(this._breakpoints, sessionID)
			return
		endif

		var breaks = this._breakpoints[sessionID]
		for break in breaks->values()
			sign_unplace(this._group, {id: break.sign})
		endfor
	enddef # }}}

	def ClearAll() # {{{2
		for breaks in this._breakpoints->values()
			for break in breaks->values()
				sign_unplace(this._group, {id: break.sign})
			endfor
		endfor
		this._breakpoints = {}
	enddef # }}}
endclass # }}}

class StepUI # {{{1
	var _id: number
	public var code: Window

	const _sigName = 'REPLDebug-Step'
	const _group = 'REPLDebug-Step'

	def new() # {{{2
		sign_define(this._sigName, {
			text: '=>',
			texthl: 'REPLDebugStep',
			linehl: 'CursorLine'
		})
	enddef # }}}

	def _MoveCursor(addr: Address) # {{{2
		var buf = this.code.GetBuffer()
		if buf.bufnr != addr.Bufnr
			this.code.SetBuf(addr.Bufnr)
			var ft = this.code.GetBuffer().GetVar('&filetype')
			if ft == ""
				this.code.Execute('filetype detect')
			endif
		endif

		this.code.SetCursor(addr.Lnum, addr.Col)
		this.code.Execute('normal! z.')
	enddef # }}}

	def RpcSet(addr: Address) # {{{2
		this._MoveCursor(addr)

		if this._id > 0
			sign_unplace(this._group, {id: this._id})
		endif

		this._id = sign_place(
			0,
			this._group,
			this._sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)
	enddef # }}}

	def Clear() # {{{2
		if this._id > 0
			sign_unplace(this._group, {id: this._id})
		endif
	enddef # }}}
endclass # }}}

class REPLDebugSession extends Ring # {{{1
	var _prompt: Window

	def RpcStop() # {{{2
		this.Pop()

		if this._prompt == null_object
			return
		endif

		if this._prompt.IsOpen()
			if !this->empty()
				this.Peek().FocusMe()
				return
			endif

			this._prompt.Close()
		endif

		this._prompt = null_object
	enddef # }}}

	def RpcFocusMe(id: number, prompt: buffer.Prompt) # {{{2
		var conf = get(g:, 'REPLDebugConfig', {})

		if this._prompt == null_object
			var promptConf = get(conf, 'prompt', {})
			this._prompt = Window.new(get(promptConf, 'pos', 'horizontal botright'), get(promptConf, 'height', 0))

			Autocmd.new('WinClosed')
				.Group(Host.REPLDebugUI.name)
				.Pattern([this._prompt.winnr->string()])
				.Once()
				.Callback(() => {
					this.ForEach((backend) => {
						backend.Stop()
					})
				})
		endif


		this._prompt.SetBuffer(prompt)
		win_gotoid(this._prompt.winnr)
		execute('startinsert')
		this.SwitchOf((b) => b.id == id)
	enddef # }}}
endclass # }}}

final Step = StepUI.new()
final Session = REPLDebugSession.new()
final Breakpoint = BreakpointUI.new()

export class REPLDebugUI extends vim.Async # {{{1
	var _code: Window

	def new() # {{{2
		this._code = Window.newCurrent()
		Step.code = this._code
		this.Open(MockBackend.new())

		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term: {reverse: true}},
			{name: 'REPLDebugStep', default: true, linksto: 'Function'}
		])

		Autocmd.new('User')
			.Group(Host.REPLDebugUI.name)
			.Pattern(Server.Names())
			.Replace()
			.Callback(this._Dispatch)
	enddef # }}}

	def Open(repl: Backend) # {{{2
		repl.Run()
		repl.FocusMe()

		if !Session->empty() && instanceof(Session.Peek(), MockBackend)
			Session.Pop().InterruptCb()
		endif

		Session.Push(repl)
	enddef # }}}

	def _RpcCall(F: func, args: list<any>): Coroutine # {{{2
		return call(function(Coroutine.new, [F]), args)
	enddef # }}}

	def _Dispatch(opt: autocmd.EventArgs) # {{{2
		def Dispatch(rpcs: list<Rpc>, server: string): Coroutine # {{{3
			return Coroutine.new(() => {
				for rpc in rpcs
					var co: Coroutine
					if server == Server.Session.name && rpc.method == 'Stop'
						co = this._SessionStop()
					else
						co = this._RpcCall(eval($'{server}.Rpc{rpc.method}'), rpc.args)
					endif

					this.Await<vim.Void>(co)
				endfor
			})
		enddef # }}}

		this.Await<vim.Void>(Dispatch(opt.data, opt.match))
	enddef # }}}

	def _Finish() # {{{2
		Step.Clear()
		Breakpoint.ClearAll()
	enddef # }}}

	def _SessionStop(): Coroutine # {{{2
		return Coroutine.new(() => {
			Session.RpcStop()
			if Session->empty()
				this.Open(MockBackend.new())
				this._Finish()
			endif
		})
	enddef # }}}

	def Next() # {{{2
		Session.SlideRight()
		Session.Peek().FocusMe()
	enddef # }}}

	def Prev() # {{{2
		Session.SlideLeft()
		Session.Peek().FocusMe()
	enddef # }}}

	def ToggleBreakpoint() # {{{2
		var buf = this._code.GetBuffer()
		var [lnum, col] = this._code.GetCursorPos()
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

		var backend = Session.Peek()
		var break = Breakpoint.GetBreakpoint(backend.id, addr)
		if break == null_object
			Server.Request(Host.REPLDebugBackend, Server.Breakpoint, Rpc.new('Break', [addr]))
		else
			Server.Request(Host.REPLDebugBackend, Server.Breakpoint, Rpc.new('Clear', break.id, break.addr))
		endif
	enddef # }}}
endclass # }}}
