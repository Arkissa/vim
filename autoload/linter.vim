vim9script

import "./log.vim"
import "./command.vim"

class Lint extends command.ErrorFormat
	def Cmd(): string
		var linter = get(b:, 'linter', "")
		if linter == ""
			throw "b:linter is empty on the buffer."
		endif

		return linter
	enddef

	def Efm(): string
		return get(b:, 'linterformat', [])->join(',')
	enddef
endclass

export var cmd: command.Command = Lint.new()
