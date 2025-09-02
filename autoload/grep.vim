vim9script

import "./errorformat.vim" as efm

export class Grep extends efm.Command
	def new(bang: bool)
		var grepprg = &grepprg

		var grepargs = get(b:, "grepargs", [])
		if !grepargs->empty()
			grepprg = $"{grepprg} {grepargs->join(' ')}"
		endif

		grepprg = substitute(grepprg, '\$\*', grepargs->join(' '), 'g') .. " $*"
		&grepprg = grepprg

		this._cmd = &grepprg
		this._efm = &grepformat
		this._bang = bang
	enddef
endclass
