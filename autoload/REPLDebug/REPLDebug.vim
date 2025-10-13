vim9script

import 'vim.vim'
import 'job.vim' as jb
import 'window.vim'
import 'buffer.vim'
import 'autocmd.vim'

type Ring = vim.Ring
type Window = window.Window
type Autocmd = autocmd.Autocmd

const group = 'REPLDebug'
final debug = vim.IncID.new()

def GetConfig(name: string): dict<any> # {{{1
	var conf = get(g:, 'REPLDebugConfig', {})
	return get(conf, name, {})
enddef # }}}

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
		var breakpoint = GetConfig('breakpoint')

		sign_define(this._sigName, {
			text: get(breakpoint, 'icon', '●'),
			texthl: 'REPLDebugBreakpoint',
			linehl: get(breakpoint, 'linehl', '')
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

	def Break(sessionID: number, breakID: number, addr: Address) # {{{2
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

	def Clear(sessionID: number, addr: Address) # {{{2
		if !has_key(this._breakpoints, sessionID)
			return
		endif

		var breaks = this._breakpoints[sessionID]
		var break = remove(breaks, addr->string())
		sign_unplace(this._group, {buffer: addr.Bufnr, id: break.sign})
	enddef # }}}

	def ClearAllByID(sessionID: number) # {{{2
		if !has_key(this._breakpoints, sessionID)
			return
		endif

		var breaks = this._breakpoints[sessionID]
		for break in breaks->values()
			sign_unplace(this._group, {id: break.sign})
		endfor
	enddef # }}}

	def Clean() # {{{2
		for breaks in this._breakpoints->values()
			for break in breaks->values()
				sign_unplace(this._group, {id: break.sign})
			endfor
		endfor
		this._breakpoints = {}
	enddef # }}}
endclass # }}}

class BreakpointCutOut # {{{1
	final _breakpoint: BreakpointUI

	def new(this._breakpoint) # {{{2
	enddef # }}}

	def Break(sessionID: number, breakID: number, addr: Address) # {{{2
		this._breakpoint.Break(sessionID, breakID, addr)
	enddef # }}}

	def Clear(sessionID: number, addr: Address) # {{{2
		this._breakpoint.Clear(sessionID, addr)
	enddef # }}}

	def ClearAll(sessionID: number) # {{{2
		this._breakpoint.ClearAllByID(sessionID)
	enddef # }}}
endclass # }}}

class StepUI # {{{1
	var _id: number
	public var code: Window

	const _sigName = 'REPLDebug-Step'
	const _group = 'REPLDebug-Step'

	def new() # {{{2
		var step = GetConfig('step')

		sign_define(this._sigName, {
			text: get(step, 'icon', '=>'),
			texthl: 'REPLDebugStep',
			linehl: get(step, 'linehl', 'CursorLine')
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

	def Mark(addr: Address) # {{{2
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

	def Clean() # {{{2
		if this._id > 0
			sign_unplace(this._group, {id: this._id})
		endif
	enddef # }}}
endclass # }}}

class StepCutOut # {{{1
	final _step: StepUI

	def new(this._step) # {{{2
	enddef # }}}

	def Mark(addr: Address) # {{{2
		this._step.Mark(addr)
	enddef # }}}
endclass # }}}

class SessionUI extends Ring # {{{1
	var prompt: Window

	static const PromptWindowPatter = 'REPLDebugPromptWindow'

	def Stop(id: number) # {{{2
		var old = this.Peek().id

		if old != id
			defer this.SwitchOf((b) => b.id == old)
		endif

		this.SwitchOf((b) => b.id == id)
		this.Pop()

		if this.prompt == null_object
			return
		endif

		if this.prompt.IsOpen()
			if !this->empty()
				this.Peek().FocusMe()
				return
			endif

			this.prompt.Close()
		endif

		this.prompt = null_object
	enddef # }}}

	def FocusMe(id: number, prompt: buffer.Prompt) # {{{2
		if this.prompt == null_object
			var prompt_window = GetConfig('prompt_window')
			var pos = get(prompt_window, 'pos', 'horizontal botright')
			var height = get(prompt_window, 'height', 0)

			this.prompt = Window.new(pos, height)

			if exists($'#{group}#WinNew#{PromptWindowPatter}')
				Autocmd.Do(group, 'WinNew', [PromptWindowPatter])
			endif
		endif

		this.prompt.SetBuffer(prompt)
		this.prompt.SetVar('&number', false)
		this.prompt.SetVar('&relativenumber', false)
		this.prompt.Execute('startinsert')

		this.SwitchOf((b) => b.id == id)
	enddef # }}}

	def Clean() # {{{2
		this.ForEach((b) => {
			b.Stop()
		})
	enddef # }}}
endclass # }}}

enum REPL # {{{1
	Step(StepUI.new()),
	Session(SessionUI.new()),
	Breakpoint(BreakpointUI.new())

	final object: any

	static def _InBlackList(name: string): bool # {{{2
		return [Session.name]->index(name) != -1
	enddef # }}}

	static def CutOuts(): dict<any> # {{{2
		var cutouts = {}
		for p in REPL.values
			if !_InBlackList(p.name)
				var CutOut = eval($'{p.name}CutOut.new')
				cutouts[p.name] = CutOut(p.object)
			endif
		endfor

		return cutouts
	enddef # }}}

	static def Clean()
		for p in REPL.values
			p.object.Clean()
		endfor
	enddef
endenum # }}}

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
	const UI = REPL.CutOuts()

	abstract def Drop(): list<string>
	abstract def Prompt(): string
	abstract def BreakpointCommand(addr: Address): string
	abstract def ClearBreakpointCommand(breakID: number, addr: Address): string
	abstract def CallbackHandles(): list<func(Context, string)>

	def Bufname(): string # {{{2
		return $'{trim(this.Prompt())}-{this.id}'
	enddef # }}}

	def ExitCb(job: job, code: number) # {{{2
		REPL.Session.object.Stop(this.id)
		super.ExitCb(job, code)
	enddef # }}}

	def FocusMe() # {{{2
		this.prompt.BashStyleKeymaps()
		REPL.Session.object.FocusMe(this.id, this.prompt)
	enddef # }}}

	def Callback(_: channel, line: string) # {{{2
		if vim.AnyRegexp(this.Drop(), line)
			return
		endif

		var i = 0
		var ctx = Context.new(this.prompt)
		var handles = this.CallbackHandles()

		while i < len(handles)
			call(handles[i], [ctx, line])

			if ctx.abort
				break
			endif

			i += 1
		endwhile

		if i >= len(handles)
			ctx.Write(line)
		endif
	enddef # }}}
endclass # }}}

class MockBackend extends Backend # {{{1
	var _breaks: dict<Address> = {}

	def new()
		Autocmd.new('User')
			.Group(jb.Prompt.Group)
			.Once()
			.Pattern(['JobRunPre'])
			.Callback(() => {
				var Session = REPL.Session.object
				if !Session->empty() && instanceof(Session.Peek(), MockBackend)
					Session.Pop()
				endif
			})
			.Pattern(['JobRunPost'])
			.Callback(() => {
				var repl = REPL.Session.object.Peek()

				this.Breaks()
					->mapnew((_, addr) => repl.BreakpointCommand(addr))
					->foreach((_, cmd) => {
						repl.Send(cmd)
					})

				REPL.Breakpoint.object.ClearAllByID(this.id)
			})
	enddef

	def Cmd(): string # {{{2
		return ''
	enddef # }}}

	def BreakpointCommand(addr: Address): string # {{{2
		this.UI.Breakpoint.Break(this.id, rand(), addr)
		this._breaks[addr->string()] = addr
		return ''
	enddef # }}}

	def ClearBreakpointCommand(_: number, addr: Address): string # {{{2
		this.UI.Breakpoint.Clear(this.id, addr)
		return ''
	enddef # }}}

	def CallbackHandles(): list<func(Context, string)> # {{{2
		return null_list
	enddef # }}}

	def Drop(): list<string> # {{{2
		return null_string
	enddef # }}}

	def FocusMe() # {{{2
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
	enddef # }}}

	def Breaks(): list<Address> # {{{2
		return this._breaks->values()
	enddef # }}}

	def Send(_: string) # {{{2
	enddef # }}}

	def Run() # {{{2
	enddef # }}}
endclass # }}}

export class REPLDebugUI # {{{1
	var _code: Window

	def new() # {{{2
		var Step = REPL.Step.object
		var Breakpoint = REPL.Breakpoint.object
		var Session = REPL.Session.object

		this._code = Window.newCurrent()
		Step.code = this._code
		this.Open(MockBackend.new())

		Autocmd.new('WinNew')
			.Group(group)
			.Pattern([SessionUI.PromptWindowPatter])
			.Callback(() => {
				Autocmd.new('WinClosed')
					.Group(group)
					.Pattern([Session.prompt.winnr->string()])
					.Once()
					.Callback(() => {
						REPL.Clean()
						this.Open(MockBackend.new())
					})
			})

		hlset([
			{name: 'REPLDebugBreakpoint', ctermfg: 'red', guifg: 'red', term: {reverse: true}},
			{name: 'REPLDebugStep', default: true, linksto: 'Function'}
		])

	enddef # }}}

	def Open(repl: Backend) # {{{2
		repl.Run()
		repl.FocusMe()
		REPL.Session.object.Push(repl)
	enddef # }}}

	def Next() # {{{2
		var Session = REPL.Session.object
		Session.SlideRight()
		Session.Peek().FocusMe()
	enddef # }}}

	def Prev() # {{{2
		var Session = REPL.Session.object
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

		var Session = REPL.Session.object
		var Breakpoint = REPL.Breakpoint.object
		var backend = Session.Peek()
		var break = Breakpoint.GetBreakpoint(backend.id, addr)
		var cmd = break == null_object
			? backend.BreakpointCommand(addr)
			: backend.ClearBreakpointCommand(break.id, break.addr)

		backend.Send(cmd)
	enddef # }}}
endclass # }}}
