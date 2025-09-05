vim9script

import "../command.vim"

class Grepprg extends command.ErrorFormat
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
