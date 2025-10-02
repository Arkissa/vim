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

enum Host
	REPLDebugUI,
	REPLDebugBackend
endenum

export class Rpc # {{{1
	var _method: string
	var args: list<any>

	def new(this._method, ...args: list<any>) # {{{2
		this.args = args
	enddef # }}}

	def Method(): string
		return $'Rpc{this._method}'
	enddef
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
		this.Bufnr = buffer.Buffer.new(this.FileName).bufnr
	enddef # }}}

	def newAll(this.FileName, this.Lnum, this.Col) # {{{2
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
	abstract def BreakpointCommand(addr: tuple<bool, Address>): string

	def Bufname(): string # {{{2
		return $'{trim(this.Prompt())}-{this.id}'
	enddef # }}}

	def ExitCb(job: job, code: number) # {{{2
		this.RequestUIServer(Server.Session, Rpc.new('Stop'))
		super.ExitCb(job, code)
	enddef # }}}

	def RequestUIServer(server: Server, ...rpcs: list<Rpc>) # {{{2
		call(function(Server.Request, [Host.REPLDebugUI, server]), rpcs)
	enddef # }}}

	def FocusMe() # {{{2
		def Brkpit(backend: Backend, opt: autocmd.EventArgs)
			var rpc: Rpc = opt.data
			var addrs: list<Address> = rpc.args
			var cmds = addrs->mapnew((_, addr) => backend.BreakpointCommand((rpc.Method() == 'Break', addr)))

			for cmd in cmds
				backend.Send(cmd)
			endfor
		enddef

		Autocmd.new('User')
			.Group(Host.REPLDebugBackend.name)
			.Pattern([Server.Breakpoint.name])
			.Replace()
			.Callback(funcref(Brkpit, [this]))
			.Pattern([Server.Session.name])
			.Replace()
			.Callback(this.Stop)

		this.RequestUIServer(Server.Session, Rpc.new('FocusMe', this.id, this.prompt))
	enddef # }}}

	def Callback(_: channel, line: string) # {{{2
		var i = 0
		var ctx = Context.new(this.prompt)
		while i < len(this.handles) && !ctx.abort
			var Handle = this.handles[i]
			Handle(ctx, line)
		endwhile
	enddef # }}}
endclass

class MockBackend extends Backend # {{{1
	var _breaks: dict<Address> = {}

	def Cmd(): string # {{{2
		return ''
	enddef # }}}

	def BreakpointCommand(_: tuple<bool, Address>): string # {{{2
		return ''
	enddef # }}}

	def FocusMe() # {{{2
		def Break(opt: autocmd.EventArgs)
			if opt.data == null
				return
			endif

			var addrs: list<Address> = opt.data
			for addr in addrs
				if opt.match == Server.Breakpoint.name
					this.RequestUIServer(
						Server.Breakpoint,
						Rpc.new('Break', this.id, addr),
					)
					this._breaks[addr->string()] = addr
				else
					this.RequestUIServer(
						Server.Breakpoint,
						Rpc.new('Clear', this.id, remove(this._breaks, addr->string())),
					)
				endif
			endfor
		enddef

		Autocmd.new('User')
			.Group(Host.REPLDebugBackend.name)
			.Pattern([Server.Breakpoint.name])
			.Replace()
			.Callback(Break)
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
		this.RequestUIServer(
			Server.Breakpoint,
			Rpc.new('Break', this._breaks->values()),
			Rpc.new('ClearAllByID', this.id),
		)
	enddef # }}}

	def Send(_: string) # {{{2
	enddef # }}}

	def Run() # {{{2
	enddef # }}}
endclass # }}}

# UI
class Breakpoint # {{{1
	static const sigName = 'REPLDebug-Variable'
	static const group = 'REPLDebug-Variable'

	static var _breakpoint: dict<dict<tuple<number, Address>>> = {}

	static def IsExists(id: number, addr: Address): bool # {{{2
		return has_key(_breakpoint, id) && has_key(_breakpoint[id], addr->string())
	enddef # }}}

	static def RpcBreak(id: number, addr: Address) # {{{2
		popup_notification('hello world', {})
		var signID = sign_place(
			0,
			group,
			sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)

		if !has_key(this._breakpoint, id)
			_breakpoint[id] = {}
		endif

		_breakpoint[id][addr->string()] = (signID, addr)
	enddef # }}}

	static def RpcClear(id: number, addr: Address) # {{{2
		if !has_key(_breakpoint, id)
			return
		endif

		var breaks = _breakpoint[id]
		var [signID, _] = remove(breaks, addr->string())
		sign_unplace(group, {buffer: addr.Bufnr, id: signID})
	enddef # }}}

	static def RpcClearAllByID(id: number) # {{{2
		if !has_key(_breakpoint, id)
			return
		endif

		var breaks = _breakpoint[id]
		for break in breaks->values()
			sign_unplace(group, {id: break[0]})
		endfor
	enddef # }}}

	static def ClearAll() # {{{2
		for breaks in _breakpoint->values()
			for break in breaks->values()
				sign_unplace(group, {id: break[0]})
			endfor
		endfor
		_breakpoint = {}
	enddef # }}}
endclass # }}}

class Step # {{{1
	static var _id: number
	public static var code: Window

	static const sigName = 'REPLDebug-Step'
	static const group = 'REPLDebug-Step'

	static def _MoveCursor(addr: Address) # {{{2
		var buf = code.GetBuffer()
		if buf.bufnr != addr.Bufnr
			code.SetBuf(addr.Bufnr)
			var ft = code.GetBuffer().GetVar('&filetype')
			if ft == ""
				code.Execute('filetype detect')
			endif
		endif

		code.SetCursor(addr.Lnum, addr.Col)
		code.FeedKeys('z.', 'mx')
	enddef # }}}

	static def RpcSet(addr: Address) # {{{2
		_MoveCursor(addr)

		if _id > 0
			sign_unplace(group, {id: this._id})
		endif

		_id = sign_place(
			0,
			group,
			sigName,
			addr.Bufnr,
			{lnum: addr.Lnum, priority: 110}
		)
	enddef # }}}

	static def Clear() # {{{2
		if this._id > 0
			sign_unplace(group, {id: this._id})
		endif
	enddef # }}}
endclass # }}}

class Session # {{{1
	static var _prompt: Window
	static var _session = Ring.new(MockBackend.new())

	static def Create(repl: Backend) # {{{2
		if !_session->empty() && instanceof(_session.Peek(), MockBackend)
			AsyncIO.Run(Coroutine.new(_session.Pop().InterruptCb))
		endif

		_session.Push(repl)
		repl.Run()
		repl.FocusMe()
	enddef # }}}

	static def RpcStop() # {{{2
		_session.Pop()

		if _session->empty()
			_session.Push(MockBackend.new())
			_Finish()
		endif

		_session.Peek().FocusMe()
	enddef # }}}

	static def RpcFocusMe(id: number, prompt: buffer.Prompt) # {{{2
		var conf = get(g:, 'REPLDebugConfig', {})

		if _prompt == null_object
			var promptConf = get(conf, 'prompt', {})
			_prompt = Window.new(get(promptConf, 'pos', 'horizontal botright'), get(promptConf, 'height', 0))

			Autocmd.new('WinClosed')
				.Group(Host.REPLDebugUI.name)
				.Pattern([_prompt.winnr->string()])
				.Once()
				.Callback(function(Server.Request, [Host.REPLDebugUI, Server.Session, Rpc.new('Stop')]))
		endif

		_prompt.SetBuffer(prompt)
		execute('startinsert')
		_session.SwitchOf((b) => b.id == id)
	enddef # }}}

	static def Peek(): any # {{{1
		return _session.Peek()
	enddef # }}}

	static def _Finish() # {{{2
		Step.Clear()
		Breakpoint.ClearAll()
	enddef # }}}

	static def Next() # {{{2
		_session.SlideRight()
		_session.Peek().FocusMe()
	enddef # }}}

	static def Prev() # {{{2
		_session.SlideLeft()
		_session.Peek().FocusMe()
	enddef # }}}
endclass # }}}

class UI extends vim.Async # {{{1
	var _code: Window

	def new() # {{{2
		this._code = Window.newCurrent()
		Step.code = this._code

		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term:  {reverse: true}},
			{name: 'REPLDebugStep', default: true, linksto: 'Function'}
		])

		sign_define(Breakpoint.sigName, {
			text: '●',
			texthl: 'REPLDebugBreakpoint',
		})

		sign_define(Step.sigName, {
			text: '=>',
			texthl: 'REPLDebugStep',
			linehl: 'CursorLine'
		})

		Autocmd.new('User')
			.Group(Host.REPLDebugUI.name)
			.Pattern(Server.Names())
			.Replace()
			.Callback(this._Dispatch)
	enddef # }}}

	def Open(repl: Backend)
		Session.Create(repl)
	enddef

	def _Dispatch(opt: autocmd.EventArgs) # {{{2
		var rpcs: list<Rpc> = opt.data

		for rpc in rpcs
			var Method = eval($'{opt.match}.{rpc.Method()}')
			timer_start(0, (_) => {
				popup_notification($'{opt.match} {rpc.Method()} Start', {})
				call(Method, rpc.args)
				popup_notification($'{opt.match} {rpc.Method()} Done', {})
			})
			popup_notification($'{opt.match} {rpc.Method()} Start', {})
			call(eval($'{opt.match}.{rpc.Method()}'), rpc.args)
			popup_notification($'{opt.match} {rpc.Method()} Done', {})
		endfor
	enddef # }}}

	def Next()
		Session.Next()
	enddef

	def Prev()
		Session.Prev()
	enddef

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
		var method = Breakpoint.IsExists(backend.id, addr) ? 'Clear' : 'Break'
		Server.Request(Host.REPLDebugBackend, Server.Breakpoint, Rpc.new(method, [addr]))
	enddef # }}}
endclass # }}}

export var REPLDebugUI = UI.new()
