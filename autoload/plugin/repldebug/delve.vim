vim9script

import autoload 'job.vim' as jb
import autoload 'buffer.vim'
import autoload './repldebug.vim'

type Method = repldebug.Method
type Address = repldebug.Address
type REPLDebugBackend = repldebug.Backend
type Context = repldebug.Context

class Delve extends REPLDebugBackend # {{{1
	var _dropRegexps = [
		'^\s\+\d\+:',
		'^=>',
		'^(dlv)\s',
	]

	var _args: list<string> = ['dlv']

	def new(prg: string) # {{{2
		this._args->extend(['exec', prg])
	enddef # }}}

	def newAttach(pid: string)
		this._args->extend(['attach', pid])
	enddef

	def Cmd(): string
		return this._args->join()
	enddef

	def Prompt(): string # {{{2
		return '(dlv) '
	enddef # }}}

	def Callback(ch: channel, msg: string)
		for regexp in this._dropRegexps
			if msg =~# regexp
				return
			endif
		endfor

		super.Callback(ch, msg)
	enddef

	def BreakpointCommand(cmd: tuple<bool, Address>): string
		var [break, addr] = cmd

		return break
			? $'break {addr.FileName}:{addr.Lnum}'
			: $'clear {addr.FileName}:{addr.Lnum}'
	enddef

	def HandleSetBreakpoint(ctx: Context, text: string)
		var m = matchlist(text, '^Breakpoint\s\d\+\sset\sat\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)')
		if m->len() != 10
			return
		endif

		var path = m[1]->split(':')
		if path->len() < 2
			return
		endif

		var [f, lnum] = path[ : 2]
		this.RequestUIMethod(Method.Breakpoint, (this.id, Address.new(f, lnum->str2nr())))
		ctx.Write(text)
		ctx.Abort()
	enddef

	def HandleClearBreakpoint(ctx: Context, text: string)
		var m = matchlist(text, '^Breakpoint\s\d\+\scleared\sat\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)')
		if m->len() != 10
			return
		endif

		var path = m[1]->split(':')
		if path->len() < 2
			return
		endif

		var [f, lnum] = path[ : 2]

		this.RequestUIMethod(Method.ClearBreakpoint, (this.id, Address.new(f, lnum->str2nr())))
		ctx.Write(text)
		ctx.Abort()
	enddef

	def HandleStep(ctx: Context, text: string)
		var m = matchlist(text, '>\s.\{-\}\s\(.\{,1\}/.*\.go:\d\+\)\s', 0, 1)
		if m->len() != 10
			return
		endif

		var path = m[1]->split(':', 1)
		if path->empty()
			return
		endif

		var [f, lnum] = path
		this.RequestUIMethod(Method.Step, Address.new(fnamemodify(f, ':.'), lnum->str2nr()))
		ctx.Abort()
	enddef

	def HandleFocusMe(ctx: Context, text: string)
		var m = matchlist(text, '>\s\[Breakpoint\s\d\+]\s.\{-\}\s\(.\{,1\}/.*\.go:\d\+\)\s', 0, 1)
		if m->len() != 10
			return
		endif

		var path = m[1]->split(':', 1)
		if path->len() != 2
			return
		endif

		var [f, lnum] = path
		this.FocusMe()
		this.RequestUIMethod(Method.Step, Address.new(fnamemodify(f, ':.'), lnum->str2nr()))
		ctx.Abort()
	enddef

	def Run()
		this.handles = [
			this.HandleFocusMe,
			this.HandleStep,
			this.HandleSetBreakpoint,
			this.HandleClearBreakpoint
		]

		super.Run()
	enddef

	def Send(text: string)
		if text == 'clearall'
			this.RequestUIMethod(Method.ClearAllBreakpoint, this.id)
		endif

		super.Send(text)
	enddef
endclass # }}}

export type Backend = Delve
