vim9script

import "./log.vim"
import "./errorformat.vim" as efm

export class Lint extends efm.Command
	var _efm: string
	var _cmd: string

	def new(this._bang)
		var linter = get(b:, 'linter', "")
		if linter == ""
			throw "b:linter is empty on the buffer."
		endif

		this._cmd = linter
		this._efm = get(b:, 'linterformat', [])->join(',')
	enddef

	def Cmd(): string
		return this._cmd
	enddef

	def Efm(): string
		return this._efm
	enddef
endclass
