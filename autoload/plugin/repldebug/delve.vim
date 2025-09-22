vim9script

import autoload 'job.vim' as jb
import autoload 'buffer.vim'
import autoload './repldebug.vim'

type REPLDebugBackend = repldebug.REPLDebugBackend
type Address = repldebug.Address

class Delve extends REPLDebugBackend # {{{1
	var _dropRegexps = [
		'^\s\+\d+',
		'^=>',
		'^(dlv)'
	]

	def new(prg: string) # {{{2
		this._cmd = $'dlv exec {prg}'
	enddef # }}}

	def newAttach(pid: string)
		this._cmd = $'dlv attach {pid}'
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

	def MakeCommand(text: string): string
		var paths = text->split(':')
		if paths->len() >= 2
			paths = paths[ : 2]
		endif

		var [f, lnum] = paths

		return has_key(this._UI.code.GetBreakpoints(this.id), $'{f}:{lnum}')
			? $'clear {f}:{lnum}'
			: $'break {f}:{lnum}'
	enddef

	def HandleToggleBreakpoint(text: string): Address
		var m = matchlist(text, '^Breakpoint\s\d\+\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)')
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

	def HandleGoto(text: string): Address
		var m = matchlist(text, '>\s\(\[Breakpoint\s\d\+]\s\)\{,1\}.\{-\}\..\{-\}()\s\(.\{,1\}/.*\.go:\d\+\)', 0, 1)
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
endclass # }}}

export type Backend = Delve
