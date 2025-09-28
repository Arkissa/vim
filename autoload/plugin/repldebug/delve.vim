vim9script

import autoload 'job.vim' as jb
import autoload 'buffer.vim'
import autoload './repldebug.vim'

type REPLDebugBackend = repldebug.REPLDebugBackend
type Address = repldebug.Address
type Method = repldebug.Method

class Delve extends REPLDebugBackend # {{{1
	var _dropRegexps = [
		'^\s\+\d+',
		'^=>',
		'^(dlv)'
	]
	var _args: list<string> = ['dlv']

	def new(prg: string) # {{{2
		this._args = ['exec', prg]
	enddef # }}}

	def newAttach(pid: string)
		this._args = ['attach', pid]
	enddef

	def Cmd(): string
		this._args->extend(['--tty', job_info(this.pty.GetJob())['tty_out']])

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

	def BreakpointCommand(addr: tuple<bool, string>): string
		var [break, text] = addr

		var paths = text->split(':')
		if paths->len() >= 2
			paths = paths[ : 2]
		endif

		var [f, lnum] = paths

		return break
			? $'break {f}:{lnum}'
			: $'clear {f}:{lnum}'
	enddef

	def HandleSetBreakpoint(text: string): Address
		var m = matchlist(text, '^Breakpoint\s\d\+\sset\sat\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)')
		if m->len() != 10
			return null_object
		endif

		var path = m[2]->split(':')
		if path->len() < 2
			return null_object
		endif

		var [f, lnum] = path[ : 2]

		return Address.new(f, lnum->str2nr())
	enddef

	def HandleClearBreakpoint(text: string): Address
		var m = matchlist(text, '^Breakpoint\s\d\+\scleared\sat\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)')
		if m->len() != 10
			return null_object
		endif

		var path = m[2]->split(':')
		if path->len() < 2
			return null_object
		endif

		var [f, lnum] = path[ : 2]

		return Address.new(f, lnum->str2nr())
	enddef

	def HandleStepFromRPEL(text: string): Address
		var m = matchlist(text, '>\s.\{-\}\..\{-\}()\s\(.\{,1\}/.*\.go:\d\+\)', 0, 1)
		if m->len() != 10
			return null_object
		endif

		var path = m[2]->split(':', 1)
		if path->empty()
			return null_object
		endif

		var [f, lnum] = path
		return Address.new(fnamemodify(f, ':.'), lnum->str2nr())
	enddef

	def HandleFocusMeFromRPEL(text: string): Address
		var m = matchlist(text, '>\s\[Breakpoint\s\d\+]\s.\{-\}\..\{-\}()\s\(.\{,1\}/.*\.go:\d\+\)', 0, 1)
		if m->len() != 10
			return null_object
		endif

		var path = m[2]->split(':', 1)
		if path->empty()
			return null_object
		endif

		var [f, lnum] = path
		return Address.new(fnamemodify(f, ':.'), lnum->str2nr())
	enddef

	def Send(text: string)
		if text == 'clearall'
			this.RequestUIMethod(Method.ClearAllBreakpoint, this.id)
		endif

		super.Send(text)
	enddef
endclass # }}}

export type Backend = Delve
