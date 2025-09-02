vim9script

import "./errorformat.vim" as efm

export class Grep extends efm.Command
	var _grepprg: string

	def new(this._bang)
		this._grepprg = &grepprg

		var grepargs = get(b:, 'grepargs', [])
		if !grepargs->empty()
			this._grepprg = substitute(this._grepprg, '\$\*', $'{grepargs->join(' ')} $*', '')
		endif
	enddef

	def Cmd(): string
		return this._grepprg
	enddef

	def Efm(): string
		return &grepformat
	enddef
endclass
