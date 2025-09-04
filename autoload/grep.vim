vim9script

import "./command.vim"

export class Grep extends command.ErrorFormat
	var _grepprg: string

	def Cmd(): string
		var grepargs = get(b:, 'grepargs', [])
		if !grepargs->empty()
			return substitute(&grepprg, '\$\*', $'{grepargs->join(' ')} $*', '')
		endif

		return &grepprg
	enddef

	def Efm(): string
		return &grepformat
	enddef
endclass

export var cmd: command.Command = Grep.new()
