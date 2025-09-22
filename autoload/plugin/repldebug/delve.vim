vim9script

import autoload 'job.vim' as jb
import autoload 'buffer.vim'
import autoload './repldebug.vim'

type REPLDebugBackend = repldebug.REPLDebugBackend
type Address = repldebug.Address

export class Delve extends REPLDebugBackend # {{{1
	var _dropRegexps = [
		'^\s\+\d+',
		'^=>',
		'^(dlv)'
	]

	def new(prg: string) # {{{2
		this._cmd = $'dlv exec {prg}'
	enddef # }}}

	def newAttach(pid: string)
		this._cmd = $'dlv attach {prg}'
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
		var [f, lnum, _] = text->split(':')

		var a = Address.new(f, lnum)
		return this._UI.code.GetBreakpointsByAddress(this.id, a) == -1 ? $'break {f}:{lnum}' : $'clear {f}:{lnum}'
	enddef

	def HandleToggleBreakpoint(text: string): tuple<number, Address>
		var m = matchlist(text, '^Breakpoint\s\(\d\+\)\s.\{-\}\(.\{,1\}/.*\.go:\d\+\)')
		if m->len() != 10
			return null_tuple
		endif

		var path = m[2]->split(':')
		if path->empty()
			return null_tuple
		endif

		var [f, lnum] = path
		return (m[1]->str2nr(), Address.new(f, lnum->str2nr()))
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
