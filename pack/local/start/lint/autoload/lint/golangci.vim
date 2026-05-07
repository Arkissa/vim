vim9script

import 'vim.vim'
import 'command.vim'

export class Lint extends command.ErrorFormat
	def Cmd(): string
		return this.Expandcmd('golangci-lint run $*')
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
