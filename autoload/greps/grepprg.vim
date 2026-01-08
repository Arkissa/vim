vim9script

import "vim.vim"
import "command.vim"

export abstract class Grepprg extends command.ErrorFormat
	abstract def GetArgs(): list<string>

	def Cmd(): string
		return this.Expandcmd(substitute(&grepprg, '\$\*', $'{vim.Cmd(this.GetArgs())} $*', ''))
	enddef

	def Efm(): string
		return &grepformat
	enddef
endclass
