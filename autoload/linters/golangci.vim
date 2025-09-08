vim9script

import '../command.vim'
import '../vim.vim'

export class GolangCiLint extends command.ErrorFormat
	def Cmd(): string
		return "golangci-lint run"
	enddef

	def Efm(): string
		return vim.Option([
			'%-G',
			'%W%f:%l:%c:\ %m',
			'%-G%\d%\+\ issues%.',
			'%-G*\ %\k%\+: %\d%\+',
		])
	enddef
endclass
