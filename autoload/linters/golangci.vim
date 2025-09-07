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
			'%E%f:%l:%c:\ Error%m',
			'%-G%\d%\+\ issues%.',
			'%-G*\ %\k%\+: %\d%\+',
		])
	enddef
endclass
