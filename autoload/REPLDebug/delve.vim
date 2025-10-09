vim9script

import 'job.vim' as jb
import 'buffer.vim'
import 'log.vim'
import autoload './REPLDebug.vim'

type Server = REPLDebug.Server
type Address = REPLDebug.Address
type REPLDebugBackend = REPLDebug.Backend
type Context = REPLDebug.Context
type Rpc = REPLDebug.Rpc

class Delve extends REPLDebugBackend # {{{1
	var _args: list<string> = ['dlv']

	def new(prg: string) # {{{2
		this._args->extend(['exec', prg])
	enddef # }}}

	def newAttach(pid: string) # {{{2
		this._args->extend(['attach', pid])
	enddef # }}}

	def Cmd(): string # {{{2
		return this._args->join()
	enddef # }}}

	def Prompt(): string # {{{2
		return '(dlv) '
	enddef # }}}

	def BreakpointCommand(addr: Address): string # {{{2
		return $'break {addr.FileName}:{addr.Lnum}'
	enddef # }}}

	def ClearBreakpointCommand(breakID: number, _: Address): string # {{{2
		return $'clear {breakID}'
	enddef # }}}

	def CallbackHandles(): list<func(Context, string)> # {{{2
	   return [
			this.HandleFocusMe,
			this.HandleSetBreakpoint,
			this.HandleClearBreakpoint,
			this.HandleStep,
		]
	enddef # }}}

	def Drop(): list<string> # {{{2
		return [
			'^(dlv)\s',
			'^\s\+\d\+:',
			'^=>',
		]
	enddef # }}}

	def ExtractAddress(text: string): Address # {{{2
		var path = text->split(':')
		if path->len() < 2
			return null_object
		endif

		var [f, lnum] = path[ : 2]
		return Address.new(fnamemodify(f, ':.'), lnum->str2nr())
	enddef # }}}

	def HandleSetBreakpoint(ctx: Context, text: string) # {{{2
		var m = matchlist(text, '^Breakpoint\s\(\d\+\)\sset\sat\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)', 0, 1)
		if m->empty()
			return
		endif

		var addr = this.ExtractAddress(m[2])
		if addr == null_object
			return
		endif

		var breakID = m[1]->str2nr()

		this.RequestUIServer(Server.Breakpoint, Rpc.new('Break', this.id, breakID, addr))
		ctx.Write(text)
		ctx.Abort()
	enddef # }}}

	def HandleClearBreakpoint(ctx: Context, text: string) # {{{2
		var m = matchlist(text, '^Breakpoint\s\d\+\scleared\sat\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)', 0, 1)
		if m->empty()
			return
		endif

		var addr = this.ExtractAddress(m[2])
		if addr == null_object
			return
		endif

		this.RequestUIServer(Server.Breakpoint, Rpc.new('Clear', this.id, addr))
		ctx.Write(text)
		ctx.Abort()
	enddef # }}}

	def HandleStep(ctx: Context, text: string) # {{{2
		var m = matchlist(text, '\zs\.\{,1\}/[^[:space:]]*\.go:\d\+', 0, 1)
		if m->empty()
			return
		endif

		var addr = this.ExtractAddress(m[0])
		if addr == null_object
			return
		endif

		this.RequestUIServer(Server.Step, Rpc.new('Set', addr))
		ctx.Abort()
	enddef # }}}

	def HandleFocusMe(_: Context, text: string) # {{{2
		var m = matchlist(text, '>\s\[Breakpoint\s\d\+]\s.\{-\}\s\(.\{,1\}/.*\.go:\d\+\)\s', 0, 1)
		if m->empty()
			return
		endif

		this.FocusMe()
	enddef # }}}

	def Send(text: string) # {{{2
		if text == 'clearall'
			this.RequestUIServer(Server.Breakpoint, Rpc.new('ClearAllByID', this.id))
		endif

		super.Send(text)
	enddef # }}}
endclass # }}}

export type Backend = Delve
