vim9script

import "vim.vim"
import "command.vim"

export abstract class Grepprg extends command.ErrorFormat
	abstract def Grepprg(): string
	abstract def GrepFormat(): string

	def GetArgs(): list<string>
		return []
	enddef

	def Cmd(): string
		return this.Expandcmd(substitute(&grepprg, '\$\*', $'{vim.Cmd(this.GetArgs())} $*', ''))
	enddef

	def Efm(): string
		return &grepformat
	enddef

	def Run()
		&grepprg = this.Grepprg()
		&grepformat = this.GrepFormat()
		super.Run()
	enddef
endclass
